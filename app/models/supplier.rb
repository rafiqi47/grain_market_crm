# app/models/supplier.rb
class Supplier < ApplicationRecord
  # Relations
  belongs_to :organization, inverse_of: :suppliers
  has_many   :products, dependent: :destroy, inverse_of: :supplier
  has_many   :purchase_orders, dependent: :restrict_with_error
  has_many   :supplier_ledgers, dependent: :restrict_with_error

  # Multi-national vs. domestic suppliers
  enum :company_type, { national: 0, multi_national: 1 }, default: :national

  # Data Normalization Callbacks
  before_validation :normalize_name

  # Validations
  validates :name, presence: true, uniqueness: {
    scope: :organization_id,
    case_sensitive: false,
    message: "has already been registered in your organization"
  }
  validates :company_type, presence: true
  validates :current_balance, presence: true, numericality: true

  # Methods
  def recalculate_ledger_balances!
    lock! # Pessimistic DB locking to guarantee isolation
    
    running_total = 0
    
    # Sort chronologically to walk down the transaction history waterfall[cite: 19]
    supplier_ledgers.chronological.each do |ledger|
      if ledger.purchase?
        running_total += ledger.amount
      elsif ledger.payment?
        running_total -= ledger.amount
      end
      
      ledger.update_column(:resulting_balance, running_total)
    end
    
    # Update the parent master profile balance cache
    update_column(:current_balance, running_total)
  end

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
