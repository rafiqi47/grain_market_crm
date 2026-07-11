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

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
