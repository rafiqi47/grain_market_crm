class CreateSalesOrdersAndLineItems < ActiveRecord::Migration[8.0]
  def change
    # 1. Sales Summary Document Table
    create_table :sales_orders do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.string :order_number, null: false
      t.decimal :total_revenue, precision: 12, scale: 2, null: false, default: 0.0
      t.decimal :total_cost, precision: 12, scale: 2, null: false, default: 0.0
      t.decimal :net_profit, precision: 12, scale: 2, null: false, default: 0.0
      t.string :customer_name
      t.datetime :placed_at, null: false

      t.timestamps
    end

    # Ensure order numbers are perfectly unique within a single organization
    add_index :sales_orders, [:organization_id, :order_number], unique: true

    # 2. Line Items Table (Explicitly tying sales down to specific batches)
    create_table :sales_line_items do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :sales_order, null: false, foreign_key: true, index: true
      t.references :product, null: false, foreign_key: true, index: true
      t.references :product_batch, null: false, foreign_key: true, index: true

      t.integer :quantity, null: false
      t.decimal :unit_price, precision: 10, scale: 2, null: false
      t.decimal :purchase_price_at_sale, precision: 10, scale: 2, null: false
      t.decimal :line_revenue, precision: 12, scale: 2, null: false
      t.decimal :line_cost, precision: 12, scale: 2, null: false
      t.decimal :line_profit, precision: 12, scale: 2, null: false

      t.timestamps
    end

    # Add DB-level constraint to guarantee an order line quantity can never be zero or negative
    execute "ALTER TABLE sales_line_items ADD CONSTRAINT check_sales_quantity_positive CHECK (quantity > 0);"
  end
end
