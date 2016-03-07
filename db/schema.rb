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

ActiveRecord::Schema.define(version: 20160307001505) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "active_admin_comments", force: :cascade do |t|
    t.string   "namespace"
    t.text     "body"
    t.string   "resource_id",   null: false
    t.string   "resource_type", null: false
    t.integer  "author_id"
    t.string   "author_type"
    t.datetime "created_at"
    t.datetime "updated_at"
  end

  add_index "active_admin_comments", ["author_type", "author_id"], name: "index_active_admin_comments_on_author_type_and_author_id", using: :btree
  add_index "active_admin_comments", ["namespace"], name: "index_active_admin_comments_on_namespace", using: :btree
  add_index "active_admin_comments", ["resource_type", "resource_id"], name: "index_active_admin_comments_on_resource_type_and_resource_id", using: :btree

  create_table "admin_users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.inet     "current_sign_in_ip"
    t.inet     "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "admin_users", ["email"], name: "index_admin_users_on_email", unique: true, using: :btree
  add_index "admin_users", ["reset_password_token"], name: "index_admin_users_on_reset_password_token", unique: true, using: :btree

  create_table "binbase_orgs", force: :cascade do |t|
    t.string   "name"
    t.string   "country_iso"
    t.string   "website"
    t.string   "phone"
    t.boolean  "is_regulated"
    t.datetime "created_at",   null: false
    t.datetime "updated_at",   null: false
  end

  create_table "binbases", force: :cascade do |t|
    t.string   "bin"
    t.string   "card_brand"
    t.string   "card_type"
    t.string   "card_category"
    t.string   "country_iso"
    t.string   "org_website"
    t.string   "org_phone"
    t.integer  "binbase_org_id"
    t.datetime "created_at",     null: false
    t.datetime "updated_at",     null: false
  end

  add_index "binbases", ["bin"], name: "index_binbases_on_bin", using: :btree

  create_table "dwolla_tokens", force: :cascade do |t|
    t.string   "access_token"
    t.string   "refresh_token"
    t.integer  "expires_in"
    t.string   "scope"
    t.string   "app_id"
    t.string   "account_id"
    t.datetime "created_at",    null: false
    t.datetime "updated_at",    null: false
  end

  create_table "embeds", force: :cascade do |t|
    t.string   "uuid"
    t.integer  "profile_id"
    t.string   "kind"
    t.json     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "embeds", ["profile_id"], name: "index_embeds_on_profile_id", using: :btree
  add_index "embeds", ["uuid"], name: "index_embeds_on_uuid", using: :btree

  create_table "merchant_configs", force: :cascade do |t|
    t.integer  "profile_id"
    t.string   "kind"
    t.json     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "merchant_configs", ["profile_id"], name: "index_merchant_configs_on_profile_id", using: :btree

  create_table "payment_sources", force: :cascade do |t|
    t.integer  "profile_id"
    t.string   "kind"
    t.json     "data"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  add_index "payment_sources", ["profile_id"], name: "index_payment_sources_on_profile_id", using: :btree

  create_table "profiles", force: :cascade do |t|
    t.string   "name"
    t.string   "email"
    t.string   "phone"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "recurring_payments", force: :cascade do |t|
    t.string   "uuid"
    t.string   "status"
    t.integer  "master_transaction_id"
    t.integer  "interval_count"
    t.string   "interval_units"
    t.date     "expires_date"
    t.date     "next_date"
    t.json     "data"
    t.datetime "created_at",            null: false
    t.datetime "updated_at",            null: false
  end

  add_index "recurring_payments", ["uuid"], name: "index_recurring_payments_on_uuid", using: :btree

  create_table "transactions", force: :cascade do |t|
    t.string   "uuid"
    t.string   "kind"
    t.string   "status"
    t.integer  "payor_id"
    t.integer  "payee_id"
    t.integer  "embed_id"
    t.integer  "payment_source_id"
    t.integer  "merchant_config_id"
    t.integer  "parent_id"
    t.decimal  "base_amount"
    t.decimal  "estimated_fee"
    t.decimal  "surcharged_fee"
    t.decimal  "platform_fee"
    t.decimal  "paid_amount"
    t.string   "description"
    t.json     "data"
    t.string   "recurrence"
    t.datetime "created_at",           null: false
    t.datetime "updated_at",           null: false
    t.string   "payment_type"
    t.integer  "recurring_payment_id"
    t.string   "mailing_list"
  end

  add_index "transactions", ["parent_id"], name: "index_transactions_on_parent_id", using: :btree
  add_index "transactions", ["payee_id"], name: "index_transactions_on_payee_id", using: :btree
  add_index "transactions", ["payor_id"], name: "index_transactions_on_payor_id", using: :btree
  add_index "transactions", ["recurring_payment_id"], name: "index_transactions_on_recurring_payment_id", using: :btree
  add_index "transactions", ["uuid"], name: "index_transactions_on_uuid", using: :btree

  create_table "users", force: :cascade do |t|
    t.string   "email",                  default: "", null: false
    t.string   "encrypted_password",     default: "", null: false
    t.string   "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.integer  "sign_in_count",          default: 0,  null: false
    t.datetime "current_sign_in_at"
    t.datetime "last_sign_in_at"
    t.string   "current_sign_in_ip"
    t.string   "last_sign_in_ip"
    t.datetime "created_at",                          null: false
    t.datetime "updated_at",                          null: false
  end

  add_index "users", ["email"], name: "index_users_on_email", unique: true, using: :btree
  add_index "users", ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true, using: :btree

  add_foreign_key "embeds", "profiles"
  add_foreign_key "merchant_configs", "profiles"
  add_foreign_key "payment_sources", "profiles"
  add_foreign_key "recurring_payments", "transactions", column: "master_transaction_id"
  add_foreign_key "transactions", "embeds"
  add_foreign_key "transactions", "merchant_configs"
  add_foreign_key "transactions", "payment_sources"
  add_foreign_key "transactions", "profiles", column: "payee_id"
  add_foreign_key "transactions", "profiles", column: "payor_id"
  add_foreign_key "transactions", "recurring_payments"
  add_foreign_key "transactions", "transactions", column: "parent_id"
end
