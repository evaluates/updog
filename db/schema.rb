# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 20161205164149) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "clicks", force: :cascade do |t|
    t.json     "data"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "contacts", force: :cascade do |t|
    t.string   "params"
    t.integer  "site_id"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "payment_notifications", force: :cascade do |t|
    t.text    "params"
    t.integer "user_id"
    t.string  "status"
    t.string  "transaction_id"
  end

  create_table "reviews", force: :cascade do |t|
    t.integer "rating"
    t.text    "comment"
    t.integer "user_id"
  end

  create_table "sites", force: :cascade do |t|
    t.integer  "uid"
    t.string   "name",            limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "subdomain",       limit: 255
    t.string   "domain",          limit: 255
    t.string   "document_root"
    t.boolean  "render_markdown"
    t.string   "db_path"
  end

  create_table "stats", force: :cascade do |t|
    t.integer  "new_users"
    t.integer  "new_upgrades"
    t.float    "percent_pro"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "subscriptions", force: :cascade do |t|
    t.string   "stripe_id"
    t.integer  "user_id"
    t.datetime "active_until"
  end

  create_table "upgradings", force: :cascade do |t|
    t.integer  "user_id"
    t.string   "source"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  create_table "users", force: :cascade do |t|
    t.string   "provider",          limit: 255
    t.integer  "uid"
    t.string   "name",              limit: 255
    t.string   "email",             limit: 255
    t.datetime "created_at"
    t.datetime "updated_at"
    t.string   "access_token",      limit: 255
    t.boolean  "is_pro"
    t.string   "full_access_token"
  end

  create_table "versions", force: :cascade do |t|
    t.string   "item_type",  limit: 255, null: false
    t.integer  "item_id",                null: false
    t.string   "event",      limit: 255, null: false
    t.string   "whodunnit",  limit: 255
    t.text     "object"
    t.datetime "created_at"
  end

  add_index "versions", ["item_type", "item_id"], name: "index_versions_on_item_type_and_item_id", using: :btree

end
