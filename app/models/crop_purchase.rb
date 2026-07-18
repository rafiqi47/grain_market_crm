# app/models/crop_purchase.rb
class CropPurchase < ApplicationRecord
  include MaundWeightConvertible

  maund_weight_field :gross_weight
  maund_weight_field :katt_deduction
  maund_weight_field :net_weight

  belongs_to :organization
  belongs_to :farmer
  belongs_to :crop
  has_one :khata_transaction, as: :sourceable, dependent: :restrict_with_error

  # Who owns the bags used for this delivery. If we (trader) supplied them,
  # the farmer owes them back to us -> posted as a bardaana debit on their Khata.
  enum :bardaana_owner, { farmer_supplied: 0, trader_supplied: 1 }, default: :farmer_supplied

  before_validation :calculate_totals
  after_create :post_to_khata!, :increase_crop_stock!

  validates :gross_weight, presence: true, numericality: { greater_than: 0 }
  validates :katt_deduction, numericality: { greater_than_or_equal_to: 0 }
  validates :market_rate, presence: true, numericality: { greater_than: 0 }
  validates :net_weight, :gross_value, :net_ledger_value, presence: true, numericality: true
  validates :purchase_date, presence: true
  validate :katt_cannot_exceed_gross_weight

  private

  # Mirrors the JS live-preview calculation exactly, so the number the user
  # saw on screen is the number that gets saved.
  #   net_weight        = gross_weight - katt_deduction               (KG)
  #   gross_value       = (net_weight / 40) * market_rate             (rate is per Maund)
  #   net_ledger_value  = gross_value - commission_amount - labor_cost
  def calculate_totals
    return if gross_weight.blank? || market_rate.blank?

    self.katt_deduction ||= 0
    self.net_weight = gross_weight - katt_deduction
    self.gross_value = (net_weight / MaundWeightConvertible::KG_PER_MAUND.to_f) * market_rate
    self.commission_amount ||= 0
    self.labor_cost ||= 0
    self.net_ledger_value = gross_value - commission_amount - labor_cost
  end

  def katt_cannot_exceed_gross_weight
    return if gross_weight.blank? || katt_deduction.blank?
    errors.add(:katt_deduction, "cannot exceed gross weight") if katt_deduction > gross_weight
  end

  def post_to_khata!
    cycle = farmer.active_khata_cycle

    # Farmer supplied bags = we owe them back -> bardaana_credit (we owe farmer more)
    # Trader supplied bags = farmer used our bags -> bardaana_debit (farmer owes us)
    farmer_bag_credit = farmer_supplied? ? bardaana_bags_count : 0
    farmer_bag_debit  = trader_supplied? ? bardaana_bags_count : 0

    KhataTransaction.create!(
      organization: organization,
      khata_cycle: cycle,
      entry_type: :credit,
      amount: net_ledger_value,
      resulting_balance: 0,
      bardaana_credit: farmer_bag_credit,
      bardaana_debit: farmer_bag_debit,
      description: "Crop purchase: #{crop.name} (#{net_weight_formatted})",
      sourceable: self
    )

    cycle.recalculate_balances!
  end

  def increase_crop_stock!
    crop.increment!(:quantity_on_hand, net_weight)
  end
end
