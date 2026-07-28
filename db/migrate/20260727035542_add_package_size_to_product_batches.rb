class AddPackageSizeToProductBatches < ActiveRecord::Migration[8.0]
  def change
    add_column :product_batches, :package_size, :decimal, precision: 10, scale: 2
  end
end
