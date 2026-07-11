class CreateProductBatches < ActiveRecord::Migration[8.0]
  def change
    create_table :product_batches do |t|
      t.references :product, null: false, foreign_key: true
      t.string :batch_number, null: false
      t.integer :initial_quantity, null: false, default: 0
      t.integer :quantity_on_hand, null: false, default: 0
      t.date :manufacture_date
      t.date :expiry_date, null: false
      t.decimal :purchase_price_per_unit, precision: 10, scale: 2, null: false, default: 0.0

      t.timestamps
    end

    # Index for fast expiry scanning (used later for background alerts)
    add_index :product_batches, :expiry_date
    # Combined index for product lot breakdowns
    add_index :product_batches, [:product_id, :batch_number]
  end
end
