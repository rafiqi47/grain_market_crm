# app/models/trading_partner.rb
class TradingPartner < ApplicationRecord
  belongs_to :organization
  has_many :trading_partner_ledgers, dependent: :restrict_with_error
  has_many :crop_sales, dependent: :restrict_with_error
  has_many :sales_orders, dependent: :restrict_with_error

  before_validation :normalize_names

  validates :business_name, presence: true, uniqueness: {
    scope: :organization_id,
    case_sensitive: false,
    message: "has already been registered in your organization"
  }
  validates :urdu_name, presence: true
  validates :address, presence: true
  validates :primary_phone, presence: true
  validates :current_balance, presence: true, numericality: true

  def display_name_full
    "#{urdu_name} — #{business_name}"
  end

  def recalculate_ledger_balances!
    lock!

    running_total = 0
    running_bardaana = 0

    trading_partner_ledgers.chronological.each do |entry|
      if entry.credit?
        running_total += entry.amount
      else
        running_total -= entry.amount
      end
      running_bardaana += (entry.bardaana_debit - entry.bardaana_credit)

      entry.update_columns(resulting_balance: running_total, resulting_bardaana_balance: running_bardaana)
    end

    update_columns(current_balance: running_total, bardaana_balance: running_bardaana)
  end

  private

  def normalize_names
    self.business_name = business_name.strip if business_name.present?
    self.urdu_name = urdu_name.strip if urdu_name.present?
  end
end
