# app/models/product_batch.rb
class ProductBatch < ApplicationRecord
  # Relations
  belongs_to :product, inverse_of: :product_batches
  belongs_to :organization, optional: true # High-speed multi-tenant shortcut query layer
  has_many   :inventory_alerts, dependent: :destroy
  has_many   :inventory_adjustments, dependent: :destroy
  has_many   :sales_line_items, dependent: :destroy

  # Validations
  validates :batch_number, presence: true
  validates :initial_quantity, numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_on_hand, numericality: { greater_than_or_equal_to: 0 }
  validates :expiry_date, presence: true
  validates :purchase_price_per_unit, numericality: { greater_than_or_equal_to: 0 }
  validate  :expiry_cannot_be_before_manufacture

  # Scopes for filtering batches safely
  scope :active, -> { where("quantity_on_hand > 0") }
  scope :expiring_within, ->(days) { where(expiry_date: Date.current..days.days.from_now.to_date) }

  def active?
    quantity_on_hand > 0
  end

  private

  def expiry_cannot_be_before_manufacture
    if manufacture_date.present? && expiry_date.present? && expiry_date < manufacture_date
      errors.add(:expiry_date, "cannot be prior to the manufacture date")
    end
  end
end
