class ChangeProductBatchesConstraintsForCommodities < ActiveRecord::Migration[8.0]
  def change
    change_column_null :product_batches, :expiry_date, true
    change_column_null :product_batches, :batch_number, true
  end
end
