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
    rescue StandardError => e
      @errors << e.message
      false
    end

    private

    # def adjust_via_purchase_order(supplier, new_value, difference)
    #   po = @batch.purchase_order

    #   new_credit = [po.amount_on_credit + difference, 0].max
    #   po.update!(
    #     total_amount:     new_value,
    #     amount_on_credit: new_credit
    #   )

    #   ledger_entry = supplier.supplier_ledgers.find_by(purchase_order: po)
    #   if ledger_entry
    #     ledger_entry.update_column(:amount, new_value)
    #   end

    #   supplier.recalculate_ledger_balances!
    # end
    def adjust_via_purchase_order(supplier, new_value, difference)
      po = @batch.purchase_order

      # Cap amount_paid at new_value — can't have paid more than the total
      new_amount_paid   = [po.amount_paid.to_f, new_value].min.round(2)
      new_amount_credit = (new_value - new_amount_paid).round(2)

      # update_columns bypasses financials_must_balance validation intentionally
      # — this is a programmatic correction, not user input
      po.update_columns(
        total_amount:     new_value.round(2),
        amount_paid:      new_amount_paid,
        amount_on_credit: new_amount_credit
      )

      ledger_entry = supplier.supplier_ledgers.find_by(purchase_order: po)
      ledger_entry&.update_column(:amount, new_value.round(2))

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
