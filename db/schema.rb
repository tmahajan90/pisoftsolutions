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

ActiveRecord::Schema[7.1].define(version: 2025_08_25_141821) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "cart_items", force: :cascade do |t|
    t.bigint "cart_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "validity_type"
    t.integer "validity_duration"
    t.decimal "validity_price"
    t.index ["cart_id"], name: "index_cart_items_on_cart_id"
    t.index ["product_id"], name: "index_cart_items_on_product_id"
  end

  create_table "carts", force: :cascade do |t|
    t.string "session_id"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id"
    t.index ["user_id"], name: "index_carts_on_user_id"
  end

  create_table "contacts", force: :cascade do |t|
    t.string "name", null: false
    t.string "phone", null: false
    t.string "email", null: false
    t.string "source"
    t.string "role"
    t.string "requirement"
    t.text "message", null: false
    t.string "contact_status", default: "new"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["contact_status"], name: "index_contacts_on_contact_status"
    t.index ["created_at"], name: "index_contacts_on_created_at"
    t.index ["email"], name: "index_contacts_on_email"
  end

  create_table "offers", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.string "discount_type"
    t.decimal "discount_value"
    t.decimal "minimum_amount"
    t.string "code"
    t.boolean "active"
    t.datetime "valid_from"
    t.datetime "valid_until"
    t.integer "usage_limit"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "order_items", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "product_id", null: false
    t.integer "quantity"
    t.decimal "price"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "validity_type"
    t.integer "validity_duration"
    t.bigint "validity_option_id"
    t.index ["order_id"], name: "index_order_items_on_order_id"
    t.index ["product_id"], name: "index_order_items_on_product_id"
    t.index ["validity_option_id"], name: "index_order_items_on_validity_option_id"
  end

  create_table "order_offers", force: :cascade do |t|
    t.bigint "order_id", null: false
    t.bigint "offer_id", null: false
    t.decimal "discount_amount"
    t.datetime "applied_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["offer_id"], name: "index_order_offers_on_offer_id"
    t.index ["order_id"], name: "index_order_offers_on_order_id"
  end

  create_table "orders", force: :cascade do |t|
    t.string "user_email"
    t.decimal "total_amount"
    t.string "status"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.string "razorpay_order_id"
    t.string "razorpay_payment_id"
    t.string "payment_status"
    t.index ["user_id"], name: "index_orders_on_user_id"
  end

  create_table "products", force: :cascade do |t|
    t.string "name"
    t.text "description"
    t.decimal "price"
    t.decimal "original_price"
    t.string "category"
    t.string "image_url"
    t.string "color"
    t.string "badge"
    t.decimal "rating"
    t.integer "stock"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.string "validity_type"
    t.integer "validity_duration"
    t.decimal "validity_price"
    t.text "validity_options"
  end

  create_table "trial_usages", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "product_id", null: false
    t.datetime "used_at"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id"], name: "index_trial_usages_on_product_id"
    t.index ["user_id", "product_id"], name: "index_trial_usages_on_user_id_and_product_id", unique: true
    t.index ["user_id"], name: "index_trial_usages_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.string "email"
    t.string "name"
    t.string "phone"
    t.string "password_digest"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.integer "role", default: 0, null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["role"], name: "index_users_on_role"
  end

  create_table "validity_options", force: :cascade do |t|
    t.bigint "product_id", null: false
    t.string "duration_type", null: false
    t.integer "duration_value", null: false
    t.decimal "price", precision: 10, scale: 2, null: false
    t.string "label", null: false
    t.boolean "is_default", default: false
    t.integer "sort_order", default: 0
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["product_id", "is_default"], name: "index_validity_options_on_product_id_and_is_default"
    t.index ["product_id", "sort_order"], name: "index_validity_options_on_product_id_and_sort_order"
    t.index ["product_id"], name: "index_validity_options_on_product_id"
  end

  add_foreign_key "cart_items", "carts"
  add_foreign_key "cart_items", "products"
  add_foreign_key "carts", "users"
  add_foreign_key "order_items", "orders"
  add_foreign_key "order_items", "products"
  add_foreign_key "order_items", "validity_options"
  add_foreign_key "order_offers", "offers"
  add_foreign_key "order_offers", "orders"
  add_foreign_key "orders", "users"
  add_foreign_key "trial_usages", "products"
  add_foreign_key "trial_usages", "users"
  add_foreign_key "validity_options", "products"
end
