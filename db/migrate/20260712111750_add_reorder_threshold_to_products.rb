class AddReorderThresholdToProducts < ActiveRecord::Migration[8.0]
  def change
    add_column :products, :reorder_threshold, :integer, default: 5, null: false
  end
end
