# app/services/inventory/receive_stock_service.rb
module Inventory
  class ReceiveStockService
    attr_reader :errors

    def initialize(organization:, supplier:, order_params:, batches_params:)
      @organization = organization
      @supplier = supplier
      @order_params = order_params     
      @batches_params = batches_params 
      @errors = []
    end

    def call
      ActiveRecord::Base.transaction do
        # 1. Pessimistic row locking to prevent race conditions during concurrent transactions
        @supplier.lock!

        # 2. Instantiate the Purchase Summary Document
        purchase_order = @organization.purchase_orders.create!(@order_params.merge(supplier: @supplier))

        # 3. Build out all nested product batches matching incoming goods
        @batches_params.each do |batch_attr|
          @organization.product_batches.create!(batch_attr)
        end

        # 4. Record Liability Increase (The entire bulk purchase value)
        running_balance = @supplier.current_balance + purchase_order.total_amount
        
        @organization.supplier_ledgers.create!(
          supplier: @supplier,
          purchase_order: purchase_order,
          entry_type: :purchase,
          amount: purchase_order.total_amount,
          resulting_balance: running_balance,
          description: "Bulk stock ingestion via Invoice ##{purchase_order.invoice_number || 'N/A'}"
        )

        # 5. Record Cash Clearing Settlement (If any downpayment/cash was paid upfront)
        if purchase_order.amount_paid > 0
          running_balance -= purchase_order.amount_paid
          
          @organization.supplier_ledgers.create!(
            supplier: @supplier,
            purchase_order: purchase_order,
            entry_type: :payment,
            amount: purchase_order.amount_paid,
            resulting_balance: running_balance,
            description: "Upfront cash settlement for Invoice ##{purchase_order.invoice_number || 'N/A'}"
          )
        end

        # 6. Synchronize the final persistent supplier balance field
        @supplier.update!(current_balance: running_balance)

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
