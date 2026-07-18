class CreateCropSales < ActiveRecord::Migration[8.0]
  def change
    create_table :crop_sales do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :trading_partner, null: false, foreign_key: true
      t.references :crop, null: false, foreign_key: true

      t.decimal :weight, precision: 12, scale: 2, null: false # stored in KG
      t.decimal :rate, precision: 12, scale: 2, null: false # Rate per Maund, as entered by the user
      t.decimal :total_value, precision: 12, scale: 2, null: false

      t.integer :bardaana_bags_count, default: 0, null: false
      t.integer :bardaana_owner, default: 0, null: false
      t.date :sale_date, null: false

      t.timestamps
    end
  end
end
