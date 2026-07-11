# app/models/sales_order.rb
class SalesOrder < ApplicationRecord
  belongs_to :organization
  has_many :sales_line_items, dependent: :destroy

  validates :order_number, presence: true, uniqueness: { scope: :organization_id }
  validates :total_revenue, :total_cost, :net_profit, presence: true, numericality: true
  validates :placed_at, presence: true
end
