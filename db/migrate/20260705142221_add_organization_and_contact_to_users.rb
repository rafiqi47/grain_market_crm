class AddOrganizationAndContactToUsers < ActiveRecord::Migration[8.0]
  def change
    add_reference :users, :organization, foreign_key: true
    add_column :users, :full_name, :string, null: false
    add_column :users, :phone, :string
  end
end
