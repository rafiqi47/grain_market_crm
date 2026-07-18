class AddUrduNameToFarmers < ActiveRecord::Migration[8.0]
  def change
    add_column :farmers, :urdu_name, :string, null: false
  end
end
