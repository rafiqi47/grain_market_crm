# app/models/farmer.rb
class Farmer < ApplicationRecord
  belongs_to :organization, inverse_of: :farmers
  has_many :khata_cycles, dependent: :restrict_with_error
  has_many :crop_purchases, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :full_name, presence: true
  validates :address, presence: true
  validates :primary_phone, presence: true, uniqueness: {
    scope: :organization_id,
    message: "has already been registered in your organization"
  }
  validates :current_balance, presence: true, numericality: true

  # Returns the single active KhataCycle, creating one if the farmer has none yet
  # (e.g. brand new farmer) or if their previous cycle was closed with a zero
  # balance and no rollover cycle was opened.
  def active_khata_cycle
    khata_cycles.find_by(status: :active) || khata_cycles.create!(organization: organization, status: :active)
  end

  private

  def normalize_name
    self.full_name = full_name.strip if full_name.present?
  end
end
