class AddUnitAndPackageSizeToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :unit, :integer, default: 0, null: false
    add_column :products, :package_size, :decimal, precision: 10, scale: 2
  end
end
