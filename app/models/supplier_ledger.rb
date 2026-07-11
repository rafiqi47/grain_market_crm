# app/models/supplier_ledger.rb
class SupplierLedger < ApplicationRecord
  belongs_to :organization
  belongs_to :supplier
  belongs_to :purchase_order, optional: true

  enum :entry_type, { purchase: 0, payment: 1 }

  validates :amount, presence: true, numericality: { greater_than: 0 }
  validates :resulting_balance, presence: true, numericality: true
  validates :entry_type, presence: true
end
