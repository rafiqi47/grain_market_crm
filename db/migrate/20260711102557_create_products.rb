class CreateProducts < ActiveRecord::Migration[8.0]
  def change
    create_table :products do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :supplier, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :category, null: false, default: 0
      t.string :sku

      t.timestamps
    end

    # Enforce unique SKUs within the same organization tenant
    add_index :products, [:organization_id, :sku], unique: true, where: "sku IS NOT NULL"
  end
end
