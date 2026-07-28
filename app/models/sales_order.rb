# app/models/sales_order.rb
class SalesOrder < ApplicationRecord
  belongs_to :organization
  belongs_to :farmer,          optional: true
  belongs_to :trading_partner, optional: true
  has_many :sales_line_items, dependent: :destroy

  enum :customer_type, { walk_in: 0, farmer_customer: 1, trading_partner_customer: 2 }, default: :walk_in

  before_validation :assign_customer_name

  validates :order_number, presence: true, uniqueness: { scope: :organization_id }
  validates :total_revenue, :total_cost, :net_profit, presence: true, numericality: true
  validates :placed_at, presence: true
  validate  :customer_reference_matches_type

  def line_items_summary
    sales_line_items.includes(:product).map do |li|
      product = li.product
      qty_str = case product.unit.to_s
      when "bag"   then "#{li.quantity.to_i} bags"
      when "piece" then "#{li.quantity.to_i} pieces"
      when "kg"
        m = (li.quantity / 40).to_i
        k = (li.quantity % 40).round(2)
        "#{m} Maund #{k} KG"
      when "ml"   then "#{li.quantity.to_i} ml"
      when "gram" then "#{li.quantity.to_i} g"
      else             "#{li.quantity}"
      end
      "#{product.name} #{qty_str}"
    end.join(", ")
  end

  private

  def assign_customer_name
    if farmer_customer? && farmer.present?
      self.customer_name = farmer.full_name
    elsif trading_partner_customer? && trading_partner.present?
      self.customer_name = trading_partner.business_name
    end
  end

  def customer_reference_matches_type
    if farmer_customer? && farmer.blank?
      errors.add(:farmer, "must be selected for a farmer sale")
    end
    if trading_partner_customer? && trading_partner.blank?
      errors.add(:trading_partner, "must be selected for a trading partner sale")
    end
    if walk_in? && farmer.present?
      errors.add(:base, "Walk-in sale cannot be linked to a farmer")
    end
    if walk_in? && trading_partner.present?
      errors.add(:base, "Walk-in sale cannot be linked to a trading partner")
    end
  end
end
