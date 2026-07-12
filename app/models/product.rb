class Product < ApplicationRecord
  # Relations
  belongs_to :organization, inverse_of: :products
  belongs_to :supplier, inverse_of: :products
  has_many   :product_batches, dependent: :destroy, inverse_of: :product
  has_many   :sales_line_items, dependent: :destroy

  enum :category, {
    fertilizer: 0,
    pesticide: 1,
    tool: 2,
    chemical: 3,
    oil_cake: 4,
    seed: 5,
    wanda: 6
  }, default: :fertilizer

  # Callbacks
  before_validation :generate_sku, on: :create, if: -> { sku.blank? }

  validates :name, presence: true
  validates :category, presence: true
  validates :sku, uniqueness: { scope: :organization_id }, allow_blank: true

  # REQUIREMENT: Combined view utility method
  def total_quantity_on_hand
    # Scans in-memory array if loaded, falls back to optimized DB sum query if not
    product_batches.target.any? ? product_batches.select(&:active?).sum(&:quantity_on_hand) : product_batches.active.sum(:quantity_on_hand)
  end

  private

  def generate_sku
    # Format pattern example: ORG-1-FERT-A8B9D1
    category_prefix = category.to_s.upcase[0..3] # Grab first 4 letters of the category

    loop do
      random_hex = SecureRandom.hex(3).upcase # Generates a 6-character random alphanumeric string
      self.sku = "ORG-#{organization_id}-#{category_prefix}-#{random_hex}"

      # Ensure collision safety within the multi-tenant organization boundary
      break unless Product.exists?(sku: sku, organization_id: organization_id)
    end
  end
end
