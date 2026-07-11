class CreateInboundPurchaseLedgerAndKhaata < ActiveRecord::Migration[8.0]
  def change
    # 1. Backport organization_id into product_batches for high-speed multi-tenant analytics
    unless column_exists?(:product_batches, :organization_id)
      add_reference :product_batches, :organization, foreign_key: true
    end

    # 2. Track the running credit/debt total for each vendor
    add_column :suppliers, :current_balance, :decimal, precision: 12, scale: 2, default: 0.0, null: false

    # 3. Create the Inbound Purchase Summary Record
    create_table :purchase_orders do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :supplier, null: false, foreign_key: true, index: true
      t.string :invoice_number
      t.decimal :total_amount, precision: 12, scale: 2, null: false, default: 0.0
      t.decimal :amount_paid, precision: 12, scale: 2, null: false, default: 0.0
      t.decimal :amount_on_credit, precision: 12, scale: 2, null: false, default: 0.0
      t.date :transaction_date, null: false

      t.timestamps
    end

    # 4. Create the Append-Only Audit Event Ledger (Khaata Stream)
    create_table :supplier_ledgers do |t|
      t.references :organization, null: false, foreign_key: true, index: true
      t.references :supplier, null: false, foreign_key: true, index: true
      t.references :purchase_order, foreign_key: true, null: true # Optional: null on manual payments
      t.integer :entry_type, null: false, default: 0 # 0: purchase (credit increases), 1: payment (credit decreases)
      t.decimal :amount, precision: 12, scale: 2, null: false
      t.decimal :resulting_balance, precision: 12, scale: 2, null: false
      t.string :description

      t.timestamps
    end

    # Add rapid filtering indexes for financial statements
    add_index :supplier_ledgers, [:supplier_id, :created_at], name: "index_supplier_ledgers_on_supplier_and_date"
  end
end
