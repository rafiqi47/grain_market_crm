class CreateInventoryAlerts < ActiveRecord::Migration[8.0]
  def change
    create_table :inventory_alerts do |t|
      t.references :organization, null: false, foreign_key: true
      t.references :product_batch, null: false, foreign_key: true
      t.integer :alert_type, null: false, default: 0
      t.string :message, null: false
      t.datetime :read_at

      t.timestamps
    end

    # Indexing for unread alerts scoped by organization tenant
    add_index :inventory_alerts, [:organization_id, :read_at]
    # Prevent duplicate active expiration alerts for the same batch
    add_index :inventory_alerts, [:product_batch_id, :alert_type], unique: true, where: "read_at IS NULL"
  end
end
