# app/models/product_batch.rb
class ProductBatch < ApplicationRecord
  # Relations
  belongs_to :product, inverse_of: :product_batches
  belongs_to :organization, optional: true 
  has_many   :inventory_alerts, dependent: :destroy
  has_many   :inventory_adjustments, dependent: :destroy
  has_many   :sales_line_items, dependent: :destroy
  belongs_to :purchase_order, optional: true

  delegate :category, to: :product, prefix: true, allow_nil: true

  # Validations - Only require these for non-commodity items
  validates :batch_number, presence: true, unless: :commodity_category?
  validates :expiry_date, presence: true, unless: :commodity_category?

  validates :initial_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_on_hand, numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price_per_unit, numericality: { greater_than_or_equal_to: 0 }
  validate  :expiry_cannot_be_before_manufacture

  scope :active, -> { where("quantity_on_hand > 0") }
  scope :expiring_within, ->(days) { where(expiry_date: Date.current..days.days.from_now.to_date) }

  def active?
    quantity_on_hand > 0
  end

  def commodity_category?
    return false if product.nil?
    %w[seed oil_cake wanda].include?(product.category.to_s)
  end

  private

  def expiry_cannot_be_before_manufacture
    # Skip evaluation if no expiry date exists
    return if expiry_date.blank?

    if manufacture_date.present? && expiry_date < manufacture_date
      errors.add(:expiry_date, "cannot be prior to the manufacture date")
    end
  end
end
