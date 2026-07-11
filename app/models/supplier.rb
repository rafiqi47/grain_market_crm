class Supplier < ApplicationRecord
  # Relations
  belongs_to :organization, inverse_of: :suppliers
  has_many   :products, dependent: :destroy, inverse_of: :supplier

  # Multi-national vs. domestic suppliers
  enum :company_type, { national: 0, multi_national: 1 }, default: :national

  # Data Normalization Callbacks
  before_validation :normalize_name

  validates :name, presence: true, uniqueness: {
    scope: :organization_id,
    case_sensitive: false,
    message: "has already been registered in your organization"
  }
  validates :company_type, presence: true

  private

  def normalize_name
    self.name = name.strip.downcase if name.present?
  end
end
