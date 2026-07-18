# app/models/khata_transaction.rb
class KhataTransaction < ApplicationRecord
  belongs_to :organization
  belongs_to :khata_cycle
  belongs_to :sourceable, polymorphic: true, optional: true

  attribute :entry_type, :integer  # explicit type declaration required by Rails 8 for integer-backed enums

  enum :entry_type, { credit: 0, debit: 1 }

  validates :amount, presence: true, numericality: { greater_than_or_equal_to: 0 }
  validates :resulting_balance, presence: true, numericality: true
  validates :entry_type, presence: true

  scope :chronological, -> { order(created_at: :asc, id: :asc) }
  scope :latest, -> { order(created_at: :desc, id: :desc) }
end
