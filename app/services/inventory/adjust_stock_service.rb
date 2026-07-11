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
        # 1. Row-lock the targeted batch inside the tenant fence
        batch = @organization.product_batches.lock.find(@product_batch_id)

        # 2. Safety Check: Verify the adjustment doesn't drop inventory below zero
        projected_qty = batch.quantity_on_hand + @quantity_changed
        if projected_qty < 0
          raise StandardError, "Adjustment rejected: Action would drop stock below zero. Current: #{batch.quantity_on_hand}, Requested: #{@quantity_changed}"
        end

        # 3. Apply change to the batch
        batch.update!(quantity_on_hand: projected_qty)

        # 4. Generate the historical audit entry
        adjustment = @organization.inventory_adjustments.create!(
          product_batch: batch,
          user: @user,
          quantity_changed: @quantity_changed,
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
