# app/models/purchase_order.rb
class PurchaseOrder < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier
  has_many :supplier_ledgers, dependent: :restrict_with_error

  validates :total_amount, :amount_paid, :amount_on_credit, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :transaction_date, presence: true
  validate :financials_must_balance

  private

  def financials_must_balance
    return if total_amount.blank? || amount_paid.blank? || amount_on_credit.blank?
    
    # Preventing decimal floating issues by rounding verification to 2 scales
    if total_amount.round(2) != (amount_paid.round(2) + amount_on_credit.round(2))
      errors.add(:base, "Total amount must exactly equal amount paid plus amount taken on credit.")
    end
  end
end
