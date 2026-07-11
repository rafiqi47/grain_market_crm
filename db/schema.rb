# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.0].define(version: 2026_07_11_140242) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "inventory_adjustments", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "product_batch_id", null: false
    t.bigint "user_id", null: false
    t.integer "quantity_changed", null: false
    t.integer "adjustment_reason", default: 0, null: false
    t.string "notes"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_inventory_adjustments_on_organization_id"
    t.index ["product_batch_id"], name: "index_inventory_adjustments_on_product_batch_id"
    t.index ["user_id"], name: "index_inventory_adjustments_on_user_id"
    t.check_constraint "quantity_changed <> 0", name: "check_quantity_changed_not_zero"
  end

  create_table "inventory_alerts", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "product_batch_id", null: false
    t.integer "alert_type", default: 0, null: false
    t.string "message", null: false
    t.datetime "read_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "read_at"], name: "index_inventory_alerts_on_organization_id_and_read_at"
    t.index ["organization_id"], name: "index_inventory_alerts_on_organization_id"
    t.index ["product_batch_id", "alert_type"], name: "index_inventory_alerts_on_product_batch_id_and_alert_type", unique: true, where: "(read_at IS NULL)"
    t.index ["product_batch_id"], name: "index_inventory_alerts_on_product_batch_id"
  end

  create_table "organizations", force: :cascade do |t|
    t.string "name", null: false
    t.string "registration_number"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "product_batches", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "batch_number", null: false
    t.integer "initial_quantity", default: 0, null: false
    t.integer "quantity_on_hand", default: 0, null: false
    t.date "manufacture_date"
    t.date "expiry_date", null: false
    t.decimal "purchase_price_per_unit", precision: 10, scale: 2, default: "0.0", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "organization_id"
    t.index ["expiry_date"], name: "index_product_batches_on_expiry_date"
    t.index ["organization_id"], name: "index_product_batches_on_organization_id"
    t.index ["product_id", "batch_number"], name: "index_product_batches_on_product_id_and_batch_number"
    t.index ["product_id"], name: "index_product_batches_on_product_id"
  end

  create_table "products", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.string "name", null: false
    t.integer "category", default: 0, null: false
    t.string "sku"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "sku"], name: "index_products_on_organization_id_and_sku", unique: true, where: "(sku IS NOT NULL)"
    t.index ["organization_id"], name: "index_products_on_organization_id"
    t.index ["supplier_id"], name: "index_products_on_supplier_id"
  end

  create_table "purchase_orders", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.string "invoice_number"
    t.decimal "total_amount", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "amount_paid", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "amount_on_credit", precision: 12, scale: 2, default: "0.0", null: false
    t.date "transaction_date", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_purchase_orders_on_organization_id"
    t.index ["supplier_id"], name: "index_purchase_orders_on_supplier_id"
  end

  create_table "sales_line_items", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "sales_order_id", null: false
    t.bigint "product_id", null: false
    t.bigint "product_batch_id", null: false
    t.integer "quantity", null: false
    t.decimal "unit_price", precision: 10, scale: 2, null: false
    t.decimal "purchase_price_at_sale", precision: 10, scale: 2, null: false
    t.decimal "line_revenue", precision: 12, scale: 2, null: false
    t.decimal "line_cost", precision: 12, scale: 2, null: false
    t.decimal "line_profit", precision: 12, scale: 2, null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_sales_line_items_on_organization_id"
    t.index ["product_batch_id"], name: "index_sales_line_items_on_product_batch_id"
    t.index ["product_id"], name: "index_sales_line_items_on_product_id"
    t.index ["sales_order_id"], name: "index_sales_line_items_on_sales_order_id"
    t.check_constraint "quantity > 0", name: "check_sales_quantity_positive"
  end

  create_table "sales_orders", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "order_number", null: false
    t.decimal "total_revenue", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "total_cost", precision: 12, scale: 2, default: "0.0", null: false
    t.decimal "net_profit", precision: 12, scale: 2, default: "0.0", null: false
    t.string "customer_name"
    t.datetime "placed_at", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id", "order_number"], name: "index_sales_orders_on_organization_id_and_order_number", unique: true
    t.index ["organization_id"], name: "index_sales_orders_on_organization_id"
  end

  create_table "supplier_ledgers", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.bigint "supplier_id", null: false
    t.bigint "purchase_order_id"
    t.integer "entry_type", default: 0, null: false
    t.decimal "amount", precision: 12, scale: 2, null: false
    t.decimal "resulting_balance", precision: 12, scale: 2, null: false
    t.string "description"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["organization_id"], name: "index_supplier_ledgers_on_organization_id"
    t.index ["purchase_order_id"], name: "index_supplier_ledgers_on_purchase_order_id"
    t.index ["supplier_id", "created_at"], name: "index_supplier_ledgers_on_supplier_and_date"
    t.index ["supplier_id"], name: "index_supplier_ledgers_on_supplier_id"
  end

  create_table "suppliers", force: :cascade do |t|
    t.bigint "organization_id", null: false
    t.string "name", null: false
    t.integer "company_type", default: 0, null: false
    t.string "phone"
    t.string "email"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.decimal "current_balance", precision: 12, scale: 2, default: "0.0", null: false
    t.index ["organization_id", "name"], name: "index_suppliers_on_organization_id_and_name"
    t.index ["organization_id"], name: "index_suppliers_on_organization_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.bigint "organization_id"
    t.string "full_name", null: false
    t.string "phone"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["organization_id"], name: "index_users_on_organization_id"
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "inventory_adjustments", "organizations"
  add_foreign_key "inventory_adjustments", "product_batches"
  add_foreign_key "inventory_adjustments", "users"
  add_foreign_key "inventory_alerts", "organizations"
  add_foreign_key "inventory_alerts", "product_batches"
  add_foreign_key "product_batches", "organizations"
  add_foreign_key "product_batches", "products"
  add_foreign_key "products", "organizations"
  add_foreign_key "products", "suppliers"
  add_foreign_key "purchase_orders", "organizations"
  add_foreign_key "purchase_orders", "suppliers"
  add_foreign_key "sales_line_items", "organizations"
  add_foreign_key "sales_line_items", "product_batches"
  add_foreign_key "sales_line_items", "products"
  add_foreign_key "sales_line_items", "sales_orders"
  add_foreign_key "sales_orders", "organizations"
  add_foreign_key "supplier_ledgers", "organizations"
  add_foreign_key "supplier_ledgers", "purchase_orders"
  add_foreign_key "supplier_ledgers", "suppliers"
  add_foreign_key "suppliers", "organizations"
  add_foreign_key "users", "organizations"
end
