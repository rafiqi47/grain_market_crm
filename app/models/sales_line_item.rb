# app/models/sales_line_item.rb
class SalesLineItem < ApplicationRecord
  belongs_to :organization
  belongs_to :sales_order
  belongs_to :product
  belongs_to :product_batch

  validates :quantity, presence: true, numericality: { greater_than: 0 }
  validates :unit_price, :purchase_price_at_sale, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :line_revenue, :line_cost, :line_profit, presence: true, numericality: true
end
