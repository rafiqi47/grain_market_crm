class CreateTradingPartners < ActiveRecord::Migration[8.0]
  def change
    create_table :trading_partners do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :business_name, null: false
      t.string :contact_person
      t.text :address, null: false
      t.string :primary_phone, null: false
      t.string :secondary_phone
      t.decimal :current_balance, precision: 12, scale: 2, default: "0.0", null: false
      t.integer :bardaana_balance, default: 0, null: false

      t.timestamps
    end

    add_index :trading_partners, [:organization_id, :business_name], unique: true, name: "index_trading_partners_on_org_and_name"
  end
end
