# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `rails
# db:schema:load`. When creating a new database, `rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema.define(version: 2020_10_26_190206) do

  # These are extensions that must be enabled in order to support this database
  enable_extension "plpgsql"

  create_table "gares", force: :cascade do |t|
    t.string "localty"
    t.string "department"
    t.string "zipcode"
    t.string "cog"
    t.float "latitude"
    t.float "longitude"
    t.string "place"
    t.string "region_sncf"
    t.string "region"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "labels", force: :cascade do |t|
    t.string "name"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "offices", force: :cascade do |t|
    t.string "name"
    t.string "sanitized_name"
    t.string "department"
    t.string "region"
    t.float "latitude"
    t.float "longitude"
    t.string "ot1"
    t.string "ot2"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  create_table "users", force: :cascade do |t|
    t.string "email", default: "", null: false
    t.string "encrypted_password", default: "", null: false
    t.string "reset_password_token"
    t.datetime "reset_password_sent_at"
    t.datetime "remember_created_at"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.string "authentication_token", limit: 30
    t.index ["authentication_token"], name: "index_users_on_authentication_token", unique: true
    t.index ["email"], name: "index_users_on_email", unique: true
    t.index ["reset_password_token"], name: "index_users_on_reset_password_token", unique: true
  end

  create_table "village_labels", force: :cascade do |t|
    t.string "link"
    t.bigint "village_id", null: false
    t.bigint "label_id", null: false
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
    t.index ["label_id"], name: "index_village_labels_on_label_id"
    t.index ["village_id"], name: "index_village_labels_on_village_id"
  end

  create_table "villages", force: :cascade do |t|
    t.string "place"
    t.string "localty"
    t.string "department"
    t.string "region"
    t.string "zipcode"
    t.string "cog"
    t.float "latitude"
    t.float "longitude"
    t.integer "population"
    t.datetime "created_at", precision: 6, null: false
    t.datetime "updated_at", precision: 6, null: false
  end

  add_foreign_key "village_labels", "labels"
  add_foreign_key "village_labels", "villages"
end
