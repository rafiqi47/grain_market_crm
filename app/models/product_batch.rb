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
  validate :initial_quantity_not_less_than_quantity_on_hand

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
    when "bag"   then "#{price.round(2)}"
    when "piece" then "#{price.round(2)}"
    when "kg"    then "#{(price * 40).round(2)}"
    when "ml"
      ps = package_size.to_f
      ps > 0 ? "#{(price * ps).round(2)}" : "#{price.round(2)}"
    when "gram"
      ps = package_size.to_f
      ps > 0 ? "#{(price * ps).round(2)}" : "#{price.round(2)}"
    else
      price.to_s
    end
  end

  def total_purchase_value
    return "—" if purchase_price_per_unit.nil?
    (purchase_price_per_unit * initial_quantity).round(2)
  end

  # Used in sales order form inventory dropdown labels
  def available_batch_details
    return "[#{quantity_on_hand} available]" if product.nil?

    case product.unit.to_s
    when "bag"   then "[#{quantity_on_hand.to_i} bags available] - Rs. #{price_display}"
    when "piece" then "[#{quantity_on_hand.to_i} pieces available] - Rs. #{price_display}"
    when "kg"
      m = (quantity_on_hand / 40).to_i
      k = (quantity_on_hand % 40).round(2)
      "[#{m}M #{k}KG available] - Rs. #{price_display}"
    when "ml"
      ps = package_size.to_f
      ps > 0 ? "[#{(quantity_on_hand / ps).floor} × #{ps.to_i}ml available] - Rs. #{price_display}" : "[#{quantity_on_hand.to_i}ml available] - Rs. #{price_display}"
    when "gram"
      ps = package_size.to_f
      ps > 0 ? "[#{(quantity_on_hand / ps).floor} × #{ps.to_i}g available] - Rs. #{price_display}" : "[#{quantity_on_hand.to_i}g available] - Rs. #{price_display}"
    else
      "[#{quantity_on_hand} available] - Rs. #{price_display}"
    end
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

  def initial_quantity_not_less_than_quantity_on_hand
    return if initial_quantity.blank? || quantity_on_hand.blank?

    if initial_quantity < quantity_on_hand
      errors.add(:initial_quantity, "can't be less than quantity on hand")
    end
  end
end
