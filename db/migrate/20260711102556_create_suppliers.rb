class CreateSuppliers < ActiveRecord::Migration[8.0]
  def change
    create_table :suppliers do |t|
      t.references :organization, null: false, foreign_key: true
      t.string :name, null: false
      t.integer :company_type, null: false, default: 0
      t.string :phone
      t.string :email

      t.timestamps
    end

    # Fast lookup for a specific organization's suppliers
    add_index :suppliers, [:organization_id, :name]
  end
end
