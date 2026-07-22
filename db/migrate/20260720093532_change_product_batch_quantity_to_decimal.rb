class ChangeProductBatchQuantityToDecimal < ActiveRecord::Migration[8.0]
  def up
    change_column :product_batches, :initial_quantity, :decimal, precision: 12, scale: 2, default: "0.0", null: false
    change_column :product_batches, :quantity_on_hand, :decimal, precision: 12, scale: 2, default: "0.0", null: false
  end

  def down
    change_column :product_batches, :initial_quantity, :integer, default: 0, null: false
    change_column :product_batches, :quantity_on_hand, :integer, default: 0, null: false
  end
end
