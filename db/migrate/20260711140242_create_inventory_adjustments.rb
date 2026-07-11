class CreateInventoryAdjustments < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_adjustments do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :product_batch, null: false, foreign_key: true, index: true
      t.references :user, null: false, foreign_key: true, index: true # Track exactly WHO made the adjustment

      t.integer :quantity_changed, null: false # Negative for damage/loss, positive for returns/restock
      t.integer :adjustment_reason, null: false, default: 0 # Enum for categorized reasons
      t.string :notes

      t.timestamps
    end

    # Database guard: prevent an adjustment record with an empty or zero shift value
    execute "ALTER TABLE inventory_adjustments ADD CONSTRAINT check_quantity_changed_not_zero CHECK (quantity_changed <> 0);"
  end
end
