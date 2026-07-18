class CreateCrops < ActiveRecord::Migration[8.0]
  def change
    create_table :crops do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.decimal :quantity_on_hand, precision: 12, scale: 2, default: "0.0", null: false # always stored in KG

      t.timestamps
    end

    add_index :crops, [:organization_id, :name], unique: true
  end
end
