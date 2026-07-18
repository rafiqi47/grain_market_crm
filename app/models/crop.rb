# app/models/crop.rb
class Crop < ApplicationRecord
  include MaundWeightConvertible
  maund_weight_field :quantity_on_hand

  belongs_to :organization
  has_many :crop_purchases, dependent: :restrict_with_error
  has_many :crop_sales, dependent: :restrict_with_error

  before_validation :normalize_name

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :quantity_on_hand, numericality: { greater_than_or_equal_to: 0 }

  private

  def normalize_name
    self.name = name.strip if name.present?
  end
end
