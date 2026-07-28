# app/models/product_batch.rb
class ProductBatch < ApplicationRecord
  belongs_to :product, inverse_of: :product_batches
  belongs_to :organization, optional: true
  belongs_to :purchase_order, optional: true
  has_many   :inventory_alerts, dependent: :destroy
  has_many   :inventory_adjustments, dependent: :destroy
  has_many   :sales_line_items, dependent: :destroy

  delegate :category, to: :product, prefix: true, allow_nil: true

  validates :batch_number, presence: true, unless: :commodity_category?
  validates :expiry_date,  presence: true, unless: :commodity_category?
  validates :package_size, presence: true, numericality: { greater_than: 0 }, if: :packet_unit?
  validates :initial_quantity,       numericality: { greater_than_or_equal_to: 0 }
  validates :quantity_on_hand,       numericality: { greater_than_or_equal_to: 0 }
  validates :purchase_price_per_unit, numericality: { greater_than_or_equal_to: 0 }
  validate  :expiry_cannot_be_before_manufacture

  scope :active,          -> { where("quantity_on_hand > 0") }
  scope :expiring_within, ->(days) { where(expiry_date: Date.current..days.days.from_now.to_date) }

  def active?
    quantity_on_hand > 0
  end

  def commodity_category?
    return false if product.nil?
    %w[seed oil_cake wanda].include?(product.category.to_s)
  end

  def packet_unit?
    %w[ml gram].include?(product&.unit.to_s)
  end

  # ── Display helpers ────────────────────────────────────────────

  def quantity_display(qty = nil)
    qty ||= quantity_on_hand
    return "—" if qty.nil?
    format_qty(qty)
  end

  def initial_quantity_display
    format_qty(initial_quantity)
  end

  # Returns a human-readable price string (no thousands delimiter — keep it plain for model layer)
  def price_display
    return "—" if purchase_price_per_unit.nil?
    price = purchase_price_per_unit
    case product&.unit.to_s
    when "bag"   then "#{price.round(2)} / bag"
    when "piece" then "#{price.round(2)} / piece"
    when "kg"    then "#{(price * 40).round(2)} / Maund"
    when "ml"
      ps = package_size.to_f
      ps > 0 ? "#{(price * ps).round(2)} / packet" : "#{price.round(2)} / ml"
    when "gram"
      ps = package_size.to_f
      ps > 0 ? "#{(price * ps).round(2)} / packet" : "#{price.round(2)} / g"
    else
      price.to_s
    end
  end

  def available_batch_details
    return "[Avail: #{self.quantity_on_hand} #{self.product.unit}]" if self.package_size.nil?

    "[Avail: #{self.quantity_on_hand.to_f/self.package_size.to_f} item/s of #{self.package_size} #{self.product.unit}"
  end

  private

  def format_qty(qty)
    return "—" if qty.nil?
    case product&.unit.to_s
    when "bag"   then "#{qty.to_i} bags"
    when "piece" then "#{qty.to_i} pieces"
    when "kg"
      m = (qty / 40).to_i
      k = (qty % 40).round(2)
      "#{m} Maund #{k} KG"
    when "ml"
      ps = package_size.to_f
      ps > 0 ? "#{(qty / ps).to_i} × #{ps.to_i} ml" : "#{qty.to_i} ml"
    when "gram"
      ps = package_size.to_f
      ps > 0 ? "#{(qty / ps).to_i} × #{ps.to_i} g" : "#{qty.to_i} g"
    else
      qty.to_s
    end
  end

  def expiry_cannot_be_before_manufacture
    return if expiry_date.blank?
    if manufacture_date.present? && expiry_date < manufacture_date
      errors.add(:expiry_date, "cannot be prior to the manufacture date")
    end
  end
end
