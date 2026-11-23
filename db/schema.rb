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

ActiveRecord::Schema[8.1].define(version: 2026_11_23_170013) do
  create_table "favorite_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "item_id", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "idx_item_id"
    t.index ["user_id", "item_id"], name: "idx_user_id_item_id", unique: true
  end

  create_table "food_log_entries", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.bigint "item_id"
    t.bigint "recipe_id"
    t.decimal "grams", precision: 7, scale: 2, null: false
    t.date "eaten_on", null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "idx_item_id"
    t.index ["recipe_id"], name: "idx_recipe_id"
    t.index ["user_id", "eaten_on"], name: "idx_user_id_eaten_on"
  end

  create_table "items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "creator_id"
    t.string "image_url", limit: 2048, collation: "utf8mb4_bin"
    t.string "name", limit: 191, null: false
    t.decimal "calories_per_100g", precision: 5, scale: 2, null: false
    t.decimal "fat_per_100g", precision: 5, scale: 2, null: false
    t.decimal "carbohydrate_per_100g", precision: 5, scale: 2, null: false
    t.decimal "fiber_per_100g", precision: 5, scale: 2, null: false
    t.decimal "protein_per_100g", precision: 5, scale: 2, null: false
    t.decimal "salt_per_100g", precision: 5, scale: 2, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.virtual "active", type: :integer, limit: 1, as: "if(isnull(`deleted_at`),1,NULL)"
    t.index ["creator_id"], name: "fk_items_creator_id"
    t.index ["name", "active"], name: "idx_name_active", unique: true
  end

  create_table "recipe_items", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "recipe_id", null: false
    t.bigint "item_id", null: false
    t.decimal "grams", precision: 7, scale: 2, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["item_id"], name: "idx_item_id"
    t.index ["recipe_id", "item_id"], name: "idx_recipe_id_item_id", unique: true
  end

  create_table "recipes", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.bigint "user_id", null: false
    t.string "name", limit: 191, null: false
    t.datetime "deleted_at", precision: nil
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.virtual "active", type: :integer, limit: 1, as: "if(isnull(`deleted_at`),1,NULL)"
    t.index ["user_id", "name", "active"], name: "idx_user_id_name_active", unique: true
  end

  create_table "users", charset: "utf8mb4", collation: "utf8mb4_unicode_ci", force: :cascade do |t|
    t.string "nickname", limit: 191, null: false
    t.string "password_digest", limit: 191, null: false, collation: "utf8mb4_bin"
    t.boolean "admin", default: false, null: false
    t.datetime "created_at", precision: nil, null: false
    t.datetime "updated_at", precision: nil, null: false
    t.index ["nickname"], name: "idx_nickname", unique: true
  end

  add_foreign_key "favorite_items", "items", name: "fk_favorite_items_item_id", on_delete: :cascade
  add_foreign_key "favorite_items", "users", name: "fk_favorite_items_user_id", on_delete: :cascade
  add_foreign_key "food_log_entries", "items", name: "fk_food_log_entries_item_id"
  add_foreign_key "food_log_entries", "recipes", name: "fk_food_log_entries_recipe_id", on_delete: :cascade
  add_foreign_key "food_log_entries", "users", name: "fk_food_log_entries_user_id", on_delete: :cascade
  add_foreign_key "items", "users", column: "creator_id", name: "fk_items_creator_id", on_delete: :nullify
  add_foreign_key "recipe_items", "items", name: "fk_recipe_items_item_id"
  add_foreign_key "recipe_items", "recipes", name: "fk_recipe_items_recipe_id", on_delete: :cascade
  add_foreign_key "recipes", "users", name: "fk_recipes_user_id", on_delete: :cascade
end
