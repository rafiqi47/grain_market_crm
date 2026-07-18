class CreateCropPurchases < ActiveRecord::Migration[8.0]
  def change
    create_table :crop_purchases do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :farmer, null: false, foreign_key: true
      t.references :crop, null: false, foreign_key: true

      # All weights stored in KG regardless of how they were entered (Maund + KG) on the form
      t.decimal :gross_weight, precision: 12, scale: 2, null: false
      t.decimal :katt_deduction, precision: 12, scale: 2, default: "0.0", null: false
      t.decimal :net_weight, precision: 12, scale: 2, null: false

      t.decimal :market_rate, precision: 12, scale: 2, null: false # Rate per Maund, as entered by the user
      t.decimal :gross_value, precision: 12, scale: 2, null: false
      t.decimal :commission_amount, precision: 12, scale: 2, default: "0.0", null: false
      t.decimal :labor_cost, precision: 12, scale: 2, default: "0.0", null: false
      t.decimal :net_ledger_value, precision: 12, scale: 2, null: false

      t.integer :bardaana_bags_count, default: 0, null: false
      t.integer :bardaana_owner, default: 0, null: false # 0 = farmer_supplied, 1 = trader_supplied
      t.date :purchase_date, null: false

      t.timestamps
    end
  end
end
