class IncreasePrecisionOnProductBatchPriceFields < ActiveRecord::Migration[8.0]
  def change
    change_column :product_batches, :purchase_price_per_unit, :decimal, precision: 14, scale: 8, default: "0.0", null: false
  end
end
