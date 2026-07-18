class CreateKhataTransactions < ActiveRecord::Migration[8.0]
  def change
    create_table :khata_transactions do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :khata_cycle, null: false, foreign_key: true
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

    add_index :khata_transactions, [:khata_cycle_id, :created_at], name: "index_khata_transactions_on_cycle_and_date"
    add_check_constraint :khata_transactions, "amount >= 0", name: "check_khata_transaction_amount_non_negative"
  end
end
