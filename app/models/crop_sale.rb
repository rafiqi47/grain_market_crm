# app/models/crop_sale.rb
class CropSale < ApplicationRecord
  include MaundWeightConvertible
  maund_weight_field :weight

  belongs_to :organization
  belongs_to :trading_partner
  belongs_to :crop
  has_one :trading_partner_ledger, as: :sourceable, dependent: :restrict_with_error

  enum :bardaana_owner, { org_supplied: 0, partner_supplied: 1 }, default: :org_supplied

  before_validation :calculate_total
  after_create :post_to_ledger!, :decrease_crop_stock!

  validates :weight, presence: true, numericality: { greater_than: 0 }
  validates :rate, presence: true, numericality: { greater_than: 0 }
  validates :total_value, presence: true, numericality: true
  validates :sale_date, presence: true
  validate :sufficient_crop_stock, on: :create

  private

  # total_value = (weight / 40) * rate   (rate is per Maund)
  def calculate_total
    return if weight.blank? || rate.blank?
    self.total_value = (weight / MaundWeightConvertible::KG_PER_MAUND.to_f) * rate
  end

  def sufficient_crop_stock
    return if crop.nil? || weight.blank?
    errors.add(:weight, "exceeds available crop stock (#{crop.quantity_on_hand_formatted} on hand)") if weight > crop.quantity_on_hand
  end

  def post_to_ledger!
    # Org supplied bags = partner owes us bags back -> bardaana_debit on their ledger
    # Partner supplied bags = we owe them bags back -> bardaana_credit on their ledger
    org_bag_debit      = org_supplied? ? bardaana_bags_count : 0
    partner_bag_credit = partner_supplied? ? bardaana_bags_count : 0

    TradingPartnerLedger.create!(
      organization: organization,
      trading_partner: trading_partner,
      entry_type: :debit,
      amount: total_value,
      resulting_balance: 0,
      bardaana_credit: partner_bag_credit,
      bardaana_debit: org_bag_debit,
      description: "Crop sale: #{crop.name} (#{weight_formatted})",
      sourceable: self
    )

    trading_partner.recalculate_ledger_balances!
  end

  def decrease_crop_stock!
    crop.decrement!(:quantity_on_hand, weight)
  end
end
