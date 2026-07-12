class AddSlugToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :slug, :string

    # Adds a unique index scoped to organization to support multi-tenant safety
    add_index :products, [:organization_id, :slug], unique: true
  end
end
