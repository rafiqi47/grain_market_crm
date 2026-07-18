# app/models/khata_cycle.rb
class KhataCycle < ApplicationRecord
  belongs_to :organization
  belongs_to :farmer
  has_many :khata_transactions, dependent: :restrict_with_error

  enum :status, { active: 0, closed: 1 }, default: :active

  validate :only_one_active_cycle_per_farmer, if: :active?

  scope :chronological, -> { order(created_at: :asc, id: :asc) }

  # Recomputes resulting_balance / resulting_bardaana_balance for every
  # transaction in this cycle, walking chronologically, exactly like
  # Supplier#recalculate_ledger_balances!
  def recalculate_balances!
    lock!

    running_total = 0
    running_bardaana = 0

    khata_transactions.chronological.each do |txn|
      if txn.credit?
        running_total += txn.amount
      else
        running_total -= txn.amount
      end
      running_bardaana += (txn.bardaana_credit - txn.bardaana_debit)

      txn.update_columns(resulting_balance: running_total, resulting_bardaana_balance: running_bardaana)
    end

    if active?
      farmer.update_columns(current_balance: running_total, bardaana_balance: running_bardaana)
    else
      update_columns(closing_balance: running_total, closing_bardaana_balance: running_bardaana)
    end
  end

  # Closes this cycle. If a balance (cash or bardaana) remains, opens a new
  # active cycle and posts a single "Balance Carried Forward" entry as its
  # first transaction.
  def close!
    transaction do
      recalculate_balances!

      last_txn = khata_transactions.chronological.last
      final_balance = last_txn&.resulting_balance || 0
      final_bardaana = last_txn&.resulting_bardaana_balance || 0

      update!(status: :closed, closed_at: Time.current, closing_balance: final_balance, closing_bardaana_balance: final_bardaana)

      next if final_balance.zero? && final_bardaana.zero?

      new_cycle = farmer.khata_cycles.create!(organization: organization, status: :active)

      KhataTransaction.create!(
        organization: organization,
        khata_cycle: new_cycle,
        entry_type: final_balance.negative? ? :debit : :credit,
        amount: final_balance.abs,
        resulting_balance: 0, # placeholder, overwritten immediately by recalculate_balances! below
        bardaana_credit: final_bardaana.positive? ? final_bardaana : 0,
        bardaana_debit: final_bardaana.negative? ? final_bardaana.abs : 0,
        description: "Balance carried forward from cycle ##{id} (closed #{closed_at.to_date})",
        sourceable: self
      )

      new_cycle.recalculate_balances!
    end
  end

  private

  def only_one_active_cycle_per_farmer
    return unless farmer_id

    existing = farmer.khata_cycles.active.where.not(id: id)
    errors.add(:base, "Farmer already has an active Khata cycle") if existing.exists?
  end
end
