class AddSlugToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :slug, :string
  end
end
