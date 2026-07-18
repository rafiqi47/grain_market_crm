# app/models/crop.rb
class Crop < ApplicationRecord
  include MaundWeightConvertible
  maund_weight_field :quantity_on_hand

  belongs_to :organization
  has_many :crop_purchases, dependent: :restrict_with_error
  has_many :crop_sales, dependent: :restrict_with_error

  before_validation :normalize_names

  validates :name, presence: true, uniqueness: { scope: :organization_id, case_sensitive: false }
  validates :urdu_slug, presence: true
  validates :quantity_on_hand, numericality: { greater_than_or_equal_to: 0 }

  def display_name_full
    "#{urdu_slug} — #{name}"
  end

  private

  def normalize_names
    self.name = name.strip if name.present?
    self.urdu_slug = urdu_slug.strip if urdu_slug.present?
  end
end
