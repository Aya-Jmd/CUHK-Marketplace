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

ActiveRecord::Schema[8.1].define(version: 2026_03_09_143419) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"
  enable_extension "pg_trgm"

  create_table "colleges", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "listing_expiry_days"
    t.string "name"
    t.datetime "updated_at", null: false
  end

  create_table "conversations", force: :cascade do |t|
    t.integer "buyer_id"
    t.datetime "created_at", null: false
    t.bigint "item_id", null: false
    t.integer "seller_id"
    t.datetime "updated_at", null: false
    t.index ["item_id"], name: "index_conversations_on_item_id"
  end

  create_table "items", force: :cascade do |t|
    t.string "category"
    t.integer "college_id"
    t.datetime "created_at", null: false
    t.text "description"
    t.boolean "is_global"
    t.float "latitude"
    t.float "longitude"
    t.decimal "price"
    t.string "title"
    t.datetime "updated_at", null: false
    t.integer "user_id"
    t.index ["category"], name: "index_items_on_category_trgm", opclass: :gin_trgm_ops, using: :gin
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

  create_table "messages", force: :cascade do |t|
    t.text "content"
    t.bigint "conversation_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "user_id", null: false
    t.index ["conversation_id"], name: "index_messages_on_conversation_id"
    t.index ["user_id"], name: "index_messages_on_user_id"
  end

  create_table "users", force: :cascade do |t|
    t.integer "college_id"
    t.datetime "created_at", null: false
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.datetime "remember_created_at"
    t.datetime "reset_password_sent_at"
    t.string "reset_password_token"
    t.datetime "updated_at", null: false
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  add_foreign_key "conversations", "items"
  add_foreign_key "messages", "conversations"
  add_foreign_key "messages", "users"
end
