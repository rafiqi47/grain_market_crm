class CreateKhataCycles < ActiveRecord::Migration[8.0]
  def change
    create_table :khata_cycles do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :farmer, null: false, foreign_key: true
      t.integer :status, default: 0, null: false
      t.datetime :closed_at
      t.decimal :closing_balance, precision: 12, scale: 2
      t.integer :closing_bardaana_balance

      t.timestamps
    end

    # Guarantees only one active cycle per farmer at any time, enforced at the DB level
    add_index :khata_cycles, [:farmer_id], unique: true, where: "(status = 0)", name: "index_one_active_cycle_per_farmer"
  end
end
