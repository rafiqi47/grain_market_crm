module Inventory
  class AdjustStockService
    attr_reader :errors

    def initialize(organization:, user:, product_batch_id:, quantity_changed:, reason:, notes: nil)
      @organization     = organization
      @user             = user
      @product_batch_id = product_batch_id
      @quantity_changed = quantity_changed.to_f  # to_f not to_i — supports commodity decimals
      @reason           = reason
      @notes            = notes
      @errors           = []
    end

    def call
      ActiveRecord::Base.transaction do
        batch = @organization.product_batches.lock.find(@product_batch_id)

        projected_qty = batch.quantity_on_hand + @quantity_changed

        if projected_qty < 0
          raise StandardError, "Adjustment would drop stock below zero (on hand: #{batch.quantity_on_hand})."
        end

        # Only cap at initial_quantity for non-returns
        if @reason != "customer_return" && projected_qty > batch.initial_quantity
          raise StandardError, "Adjustment would exceed initial batch quantity of #{batch.initial_quantity}."
        end

        batch.update!(quantity_on_hand: projected_qty)

        @organization.inventory_adjustments.create!(
          product_batch:     batch,
          user:              @user,
          quantity_changed:  @quantity_changed,
          adjustment_reason: @reason,
          notes:             @notes
        )
      end
    rescue ActiveRecord::RecordInvalid => e
      @errors << e.message
      false
    rescue StandardError => e
      @errors << e.message
      false
    end
  end
end
