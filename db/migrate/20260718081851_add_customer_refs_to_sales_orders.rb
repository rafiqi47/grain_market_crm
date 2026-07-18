class AddCustomerRefsToSalesOrders < ActiveRecord::Migration[8.0]
  def change
    add_reference :sales_orders, :farmer, null: true, foreign_key: true
    add_reference :sales_orders, :trading_partner, null: true, foreign_key: true
    add_column :sales_orders, :customer_type, :integer, default: 0, null: false
    # 0 = walk_in, 1 = farmer, 2 = trading_partner
  end
end
