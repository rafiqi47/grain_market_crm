class Product < ApplicationRecord
  # Relations
  belongs_to :organization, inverse_of: :products
  belongs_to :supplier, inverse_of: :products
  has_many   :product_batches, dependent: :destroy, inverse_of: :product

  enum :category, { fertilizer: 0, pesticide: 1, tool: 2, chemical: 3 }, default: :fertilizer

  validates :name, presence: true
  validates :category, presence: true
  validates :sku, uniqueness: { scope: :organization_id }, allow_blank: true

  # REQUIREMENT: Combined view utility method
  def total_quantity_on_hand
    # Scans in-memory array if loaded, falls back to optimized DB sum query if not
    product_batches.target.any? ? product_batches.select(&:active?).sum(&:quantity_on_hand) : product_batches.active.sum(:quantity_on_hand)
  end
end
