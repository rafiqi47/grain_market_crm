# app/services/inventory/receive_stock_service.rb
module Inventory
  class ReceiveStockService
    attr_reader :errors

    def initialize(organization:, supplier:, order_params:, batches_params:)
      @organization = organization
      @supplier = supplier
      @order_params = order_params     # e.g., { total_amount: 5000.00, amount_paid: 2000.00, amount_on_credit: 3000.00, transaction_date: Date.today, invoice_number: "INV-99" }
      @batches_params = batches_params # Array of hashes: [{ product_id: 1, batch_number: "B1", initial_quantity: 100, quantity_on_hand: 100, expiry_date: Date.today + 1.year, purchase_price_per_unit: 50.00 }]
      @errors = []
    end

    def call
      ActiveRecord::Base.transaction do
        # 1. Instantiate the Purchase Summary Document
        purchase_order = @organization.purchase_orders.create!(@order_params.merge(supplier: @supplier))

        # 2. Build out all nested product batches matching incoming goods
        @batches_params.each do |batch_attr|
          @organization.product_batches.create!(batch_attr)
        end

        # 3. Handle credit tracking logic (Khaata allocation)
        if purchase_order.amount_on_credit > 0
          # Row locking to prevent race conditions during heavy parallel updates
          @supplier.lock!

          new_balance = @supplier.current_balance + purchase_order.amount_on_credit
          @supplier.update!(current_balance: new_balance)

          # 4. Append to ledger event stream
          @organization.supplier_ledgers.create!(
            supplier: @supplier,
            purchase_order: purchase_order,
            entry_type: :purchase,
            amount: purchase_order.amount_on_credit,
            resulting_balance: new_balance,
            description: "Stock ingested via Invoice ##{purchase_order.invoice_number}"
          )
        end

        purchase_order
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue StandardError => e
      @errors << "Transaction aborted: #{e.message}"
      false
    end
  end
end
