# app/models/farmer.rb
class Farmer < ApplicationRecord
  belongs_to :organization, inverse_of: :farmers
  has_many :khata_cycles, dependent: :restrict_with_error
  has_many :crop_purchases, dependent: :restrict_with_error
  has_many :sales_orders, dependent: :restrict_with_error

  before_validation :normalize_names

  validates :full_name, presence: true
  validates :urdu_name, presence: true
  validates :address, presence: true
  validates :primary_phone, presence: true, uniqueness: {
    scope: :organization_id,
    message: "has already been registered in your organization"
  }
  validates :current_balance, presence: true, numericality: true

  def active_khata_cycle
    khata_cycles.find_by(status: :active) || khata_cycles.create!(organization: organization, status: :active)
  end

  # Display name for print: Urdu name + English name
  def display_name_full
    "#{urdu_name} — #{full_name}"
  end

  private

  def normalize_names
    self.full_name = full_name.strip if full_name.present?
    self.urdu_name = urdu_name.strip if urdu_name.present?
  end
end
