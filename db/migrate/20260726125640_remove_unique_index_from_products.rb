class RemoveUniqueIndexFromProducts < ActiveRecord::Migration[8.0]
  def change
    remove_index :products, name: "index_products_on_organization_id_and_slug"
  end
end
