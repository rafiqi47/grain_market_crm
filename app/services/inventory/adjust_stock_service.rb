# app/services/inventory/adjust_stock_service.rb
module Inventory
  class AdjustStockService
    attr_reader :errors

    def initialize(organization:, user:, product_batch_id:, quantity_changed:, reason:, notes: nil)
      @organization = organization
      @user = user
      @product_batch_id = product_batch_id
      @quantity_changed = quantity_changed.to_i
      @reason = reason
      @notes = notes
      @errors = []
    end

    def call
      ActiveRecord::Base.transaction do
        batch = @organization.product_batches.lock.find(@product_batch_id)

        # 1. Determine the actual change (logic from previous step)
        deduction_reasons = ['damaged_goods', 'spillage_or_leakage', 'supplier_return']
        actual_change = if deduction_reasons.include?(@reason)
                          -@quantity_changed.abs
                        else
                          @quantity_changed.abs
                        end

        projected_qty = batch.quantity_on_hand + actual_change

        # 2. Safety Check: Verify the adjustment doesn't drop inventory below zero
        if projected_qty < 0
          raise StandardError, "Adjustment rejected: Action would drop stock below zero."
        end

        # 3. New Safety Check: Verify the adjustment doesn't exceed initial quantity
        if projected_qty > batch.initial_quantity
          raise StandardError, "Adjustment rejected: Action would exceed initial batch quantity of #{batch.initial_quantity}."
        end

        # 4. Apply change to the batch
        batch.update!(quantity_on_hand: projected_qty)

        # 5. Generate the historical audit entry
        adjustment = @organization.inventory_adjustments.create!(
          product_batch: batch,
          user: @user,
          quantity_changed: actual_change,
          adjustment_reason: @reason,
          notes: @notes
        )

        adjustment
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue StandardError => e
      @errors << "Adjustment failed: #{e.message}"
      false
    end
  end
end
