# app/models/inventory_adjustment.rb
class InventoryAdjustment < ApplicationRecord
  belongs_to :organization
  belongs_to :product_batch
  belongs_to :user

  # Define specific adjustment types
  enum :adjustment_reason, {
    damaged_goods: 0,
    spillage_or_leakage: 1,
    supplier_return: 2,
    customer_return: 3,
    audit_correction: 4
  }, default: :damaged_goods

  validates :quantity_changed, presence: true, numericality: { other_than: 0 }
  validates :adjustment_reason, presence: true
  validates :notes, presence: true, length: { minimum: 5 }, if: :requires_notes?

  private

  def requires_notes?
    audit_correction? || supplier_return?
  end
end
