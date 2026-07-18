# app/models/sales_order.rb
class SalesOrder < ApplicationRecord
  belongs_to :organization
  belongs_to :farmer, optional: true
  belongs_to :trading_partner, optional: true
  has_many :sales_line_items, dependent: :destroy

  enum :customer_type, { walk_in: 0, farmer_customer: 1, trading_partner_customer: 2 }, default: :walk_in

  before_validation :assign_customer_name

  validates :order_number, presence: true, uniqueness: { scope: :organization_id }
  validates :total_revenue, :total_cost, :net_profit, presence: true, numericality: true
  validates :placed_at, presence: true
  validate :customer_reference_matches_type

  private

  # Auto-fills customer_name from the associated record so existing
  # reporting that reads customer_name stays accurate
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
