# app/services/inventory/adjust_batch_service.rb
module Inventory
  class AdjustBatchService
    attr_reader :errors

    def initialize(batch:, old_quantity:, old_price:, new_quantity:, new_price:, organization:)
      @batch        = batch
      @old_quantity = old_quantity.to_f
      @old_price    = old_price.to_f
      @new_quantity = new_quantity.to_f
      @new_price    = new_price.to_f
      @organization = organization
      @errors       = []
    end

    def call
      old_value  = @old_quantity * @old_price
      new_value  = @new_quantity * @new_price
      difference = new_value - old_value

      return true if difference.abs < 0.01

      supplier = @batch.product.supplier

      ActiveRecord::Base.transaction do
        if @batch.purchase_order.present?
          adjust_via_purchase_order(supplier, new_value, difference)
        else
          post_adjustment_entry(supplier, difference)
        end
      end

      true
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    end

    private

    def adjust_via_purchase_order(supplier, new_value, difference)
      po = @batch.purchase_order

      new_credit = [po.amount_on_credit + difference, 0].max
      po.update!(
        total_amount:     new_value,
        amount_on_credit: new_credit
      )

      ledger_entry = supplier.supplier_ledgers.find_by(purchase_order: po)
      if ledger_entry
        ledger_entry.update_column(:amount, new_value)
      end

      supplier.recalculate_ledger_balances!
    end

    def post_adjustment_entry(supplier, difference)
      last_balance = supplier.supplier_ledgers
                             .chronological
                             .last&.resulting_balance || 0

      if difference > 0
        supplier.supplier_ledgers.create!(
          organization:      @organization,
          entry_type:        :purchase,
          amount:            difference.abs,
          resulting_balance: last_balance + difference.abs,
          description:       "Batch adjustment +#{difference.abs.round(2)} — #{@batch.product.name} (#{@batch.batch_number.presence || 'no batch #'})"
        )
      else
        supplier.supplier_ledgers.create!(
          organization:      @organization,
          entry_type:        :payment,
          amount:            difference.abs,
          resulting_balance: last_balance - difference.abs,
          description:       "Batch adjustment -#{difference.abs.round(2)} — #{@batch.product.name} (#{@batch.batch_number.presence || 'no batch #'})"
        )
      end

      supplier.update_column(:current_balance, supplier.supplier_ledgers.chronological.last.resulting_balance)
    end
  end
end
