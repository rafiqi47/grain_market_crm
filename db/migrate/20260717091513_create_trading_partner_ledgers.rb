class CreateTradingPartnerLedgers < ActiveRecord::Migration[8.0]
  def change
    create_table :trading_partner_ledgers do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :trading_partner, null: false, foreign_key: true
      t.integer :entry_type, null: false
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :resulting_balance, precision: 12, scale: 2, null: false
      t.integer :bardaana_credit, default: 0, null: false
      t.integer :bardaana_debit, default: 0, null: false
      t.integer :resulting_bardaana_balance, default: 0, null: false
      t.string :description
      t.references :sourceable, polymorphic: true, null: true
      t.timestamps
    end

    add_index :trading_partner_ledgers, [:trading_partner_id, :created_at], name: "index_tp_ledgers_on_partner_and_date"
    add_check_constraint :trading_partner_ledgers, "amount >= 0", name: "check_tp_ledger_amount_non_negative"
  end
end
