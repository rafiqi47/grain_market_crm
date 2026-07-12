# app/models/supplier_ledger.rb
class SupplierLedger < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier
  belongs_to :purchase_order, optional: true

  enum :entry_type, { purchase: 0, payment: 1 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :resulting_balance, presence: true, numericality: true
  validates :entry_type, presence: true

  # Sorting scope to view the ledger stream exactly as it happened
  scope :chronological, -> { order(created_at: :asc, id: :asc) }
  scope :latest, -> { order(created_at: :desc, id: :desc) }
end
