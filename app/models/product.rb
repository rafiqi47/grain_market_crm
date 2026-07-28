class Product < ApplicationRecord
  # Relations
  belongs_to :organization, inverse_of: :products
  belongs_to :supplier, inverse_of: :products
  has_many   :product_batches, dependent: :destroy, inverse_of: :product
  has_many   :sales_line_items, dependent: :destroy

  # Enums
  enum :category, {
    fertilizer: 0,
    pesticide: 1,
    tool: 2,
    chemical: 3,
    oil_cake: 4,
    seed: 5,
    wanda: 6
  }, default: :fertilizer

  enum :unit, {
    bag: 0,
    ml: 1,
    gram: 2,
    piece: 3,
    kg: 4
  }, default: :bag

  # Map allowed units per category
  ALLOWED_UNITS = {
    "fertilizer" => %w[bag],
    "pesticide"  => %w[ml gram],
    "chemical"   => %w[ml gram],
    "tool"       => %w[piece],
    "oil_cake"   => %w[kg],
    "seed"       => %w[kg],
    "wanda"      => %w[kg]
  }.freeze

  # Callbacks
  before_validation :generate_sku, on: :create, if: -> { sku.blank? }
  before_validation :clean_urdu_slug

  # Validations
  validates :name, presence: true
  validates :category, presence: true
  validates :unit, presence: true
  validates :sku, uniqueness: { scope: :organization_id }, allow_blank: true
  validates :reorder_threshold, numericality: { greater_than_or_equal_to: 0 }
  validates :slug, presence: true
  
  validate :validate_unit_for_category

  # Scopes
  scope :low_stock, -> {
    joins(:product_batches)
      .group('products.id')
      .having('SUM(product_batches.quantity_on_hand) < products.reorder_threshold')
  }

  def low_stock?
    total_quantity_on_hand < reorder_threshold
  end

  def suggested_reorder_quantity
    return 0 unless low_stock?
    (reorder_threshold * 2) - total_quantity_on_hand
  end

  def total_quantity_on_hand
    product_batches.target.any? ? product_batches.select(&:active?).sum(&:quantity_on_hand) : product_batches.active.sum(:quantity_on_hand)
  end

  private

  def validate_unit_for_category
    return if category.blank? || unit.blank?

    allowed = ALLOWED_UNITS[category.to_s] || []
    unless allowed.include?(unit.to_s)
      errors.add(:unit, "is invalid for category '#{category}'. Allowed units: #{allowed.join(', ')}")
    end
  end

  def generate_sku
    category_prefix = category.to_s.upcase[0..3]

    loop do
      random_hex = SecureRandom.hex(3).upcase
      self.sku = "ORG-#{organization_id}-#{category_prefix}-#{random_hex}"
      break unless Product.exists?(sku: sku, organization_id: organization_id)
    end
  end

  def clean_urdu_slug
    return if slug.blank?
    self.slug = slug.strip.gsub(/\s+/, '-')
  end
end
