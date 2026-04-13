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

ActiveRecord::Schema[8.1].define(version: 2026_04_13_094500) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "fuzzystrmatch"
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"
  enable_extension "unaccent"

  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "categories", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_categories_on_name", unique: true
  end

  create_table "colleges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "listing_expiry_days"
    t.string "name"
    t.string "slug", null: false
    t.datetime "updated_at", null: false
    t.index ["slug"], name: "index_colleges_on_slug", unique: true
  end

  create_table "conversations", force: :cascade do |t|
    t.integer "buyer_id"
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.integer "seller_id"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_conversations_on_item_id"
  end

  create_table "currencies", force: :cascade do |t|
    t.string "code"
    t.datetime "created_at", null: false
    t.string "name"
    t.decimal "rate_from_hkd"
    t.string "symbol"
    t.datetime "updated_at", null: false
  end

  create_table "favorites", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["item_id"], name: "index_favorites_on_item_id"
    t.index ["user_id", "item_id"], name: "index_favorites_on_user_id_and_item_id", unique: true
    t.index ["user_id"], name: "index_favorites_on_user_id"
  end

  create_table "item_reports", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.text "message", null: false
    t.bigint "reporter_id", null: false
    t.datetime "resolved_at"
    t.bigint "resolved_by_id"
    t.string "status", default: "pending", null: false
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_item_reports_on_item_id"
    t.index ["reporter_id"], name: "index_item_reports_on_reporter_id"
    t.index ["resolved_by_id"], name: "index_item_reports_on_resolved_by_id"
    t.index ["status"], name: "index_item_reports_on_status"
  end

  create_table "items", force: :cascade do |t|
    t.bigint "category_id"
    t.integer "college_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_global"
    t.float "latitude"
    t.string "location_name"
    t.float "longitude"
    t.decimal "price"
    t.datetime "sold_at"
    t.string "status", default: "available", null: false
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["category_id"], name: "index_items_on_category_id"
    t.index ["description"], name: "index_items_on_description_trgm", opclass: :gin_trgm_ops, using: :gin
    t.index ["title"], name: "index_items_on_title_trgm", opclass: :gin_trgm_ops, using: :gin
  end

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "notifications", force: :cascade do |t|
    t.string "action"
    t.bigint "actor_id", null: false
    t.decimal "amount_hkd"
    t.datetime "created_at", null: false
    t.bigint "notifiable_id", null: false
    t.string "notifiable_type", null: false
    t.datetime "read_at"
    t.bigint "recipient_id", null: false
    t.datetime "updated_at", null: false
    t.index ["actor_id"], name: "index_notifications_on_actor_id"
    t.index ["notifiable_type", "notifiable_id"], name: "index_notifications_on_notifiable"
    t.index ["recipient_id"], name: "index_notifications_on_recipient_id"
  end

  create_table "offers", force: :cascade do |t|
    t.bigint "buyer_id", null: false
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.string "meetup_code"
    t.decimal "price", null: false
    t.bigint "seller_id", null: false
    t.string "status", default: "pending"
    t.datetime "updated_at", null: false
    t.index ["buyer_id"], name: "index_offers_on_buyer_id"
    t.index ["item_id", "buyer_id"], name: "index_offers_on_item_id_and_buyer_id", unique: true
    t.index ["item_id"], name: "index_offers_on_item_id"
    t.index ["seller_id"], name: "index_offers_on_seller_id"
  end

  create_table "users", force: :cascade do |t|
    t.datetime "banned_at"
    t.bigint "banned_by_id"
    t.integer "college_id"
    t.datetime "created_at", null: false
    t.string "default_location"
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.float "latitude"
    t.float "longitude"
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.integer "role", default: 0, null: false
    t.boolean "setup_completed", default: false
    t.datetime "updated_at", null: false
    t.index ["banned_by_id"], name: "index_users_on_banned_by_id"
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "conversations", "items"
  add_foreign_key "favorites", "items"
  add_foreign_key "favorites", "users"
  add_foreign_key "item_reports", "items"
  add_foreign_key "item_reports", "users", column: "reporter_id"
  add_foreign_key "item_reports", "users", column: "resolved_by_id"
  add_foreign_key "items", "categories"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
  add_foreign_key "notifications", "users", column: "actor_id"
  add_foreign_key "notifications", "users", column: "recipient_id"
  add_foreign_key "offers", "items"
  add_foreign_key "offers", "users", column: "buyer_id"
  add_foreign_key "offers", "users", column: "seller_id"
  add_foreign_key "users", "users", column: "banned_by_id"
end
