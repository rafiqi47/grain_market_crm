class AddPurchaseOrderToProductBatches < ActiveRecord::Migration[8.0]
  def change
    add_reference :product_batches, :purchase_order, null: true, foreign_key: true
  end
end
