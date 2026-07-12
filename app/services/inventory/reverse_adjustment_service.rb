module Inventory
  class ReverseAdjustmentService
    def initialize(original_adjustment, user)
      @original = original_adjustment
      @user = user
      @organization = original_adjustment.organization
    end

    def call
      ActiveRecord::Base.transaction do
        reversal_qty = -@original.quantity_changed
        
        Inventory::AdjustStockService.new(
          organization: @organization,
          user: @user,
          product_batch_id: @original.product_batch_id,
          quantity_changed: reversal_qty,
          reason: 'audit_correction',
          notes: "Reversal of Adjustment ##{@original.id}: #{@original.notes}"
        ).call
      end
    end
  end
end