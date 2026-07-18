class CreateFarmers < ActiveRecord::Migration[8.0]
  def change
    create_table :farmers do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :full_name, null: false
      t.text :address, null: false
      t.string :primary_phone, null: false
      t.string :secondary_phone
      t.decimal :current_balance, precision: 12, scale: 2, default: "0.0", null: false
      t.integer :bardaana_balance, default: 0, null: false

      t.timestamps
    end

    add_index :farmers, [:organization_id, :primary_phone], unique: true, name: "index_farmers_on_org_and_primary_phone"
  end
end
