class AddUrduNameToOrganizations < ActiveRecord::Migration[8.0]
  def change
    add_column :organizations, :urdu_name, :string
  end
end
