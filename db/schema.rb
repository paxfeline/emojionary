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

ActiveRecord::Schema[7.0].define(version: 2023_07_09_213743) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pgcrypto"
  enable_extension "plpgsql"

  create_table "game_states", force: :cascade do |t|
    t.uuid "player_id", null: false
    t.uuid "game_id", null: false
    t.string "state"
    t.boolean "ready"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_game_states_on_game_id"
    t.index ["player_id"], name: "index_game_states_on_player_id"
  end

  create_table "games", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "title"
    t.uuid "judge_id", null: false
    t.string "deck"
    t.boolean "judging"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.bigint "prompt_id"
    t.index ["judge_id"], name: "index_games_on_judge_id"
    t.index ["prompt_id"], name: "index_games_on_prompt_id"
  end

  create_table "players", id: :uuid, default: -> { "gen_random_uuid()" }, force: :cascade do |t|
    t.string "name"
    t.datetime "last_judged"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
  end

  create_table "prompts", force: :cascade do |t|
    t.string "prompt"
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.uuid "game_id"
    t.index ["game_id"], name: "index_prompts_on_game_id"
  end

  create_table "used_prompts", force: :cascade do |t|
    t.bigint "prompt_id", null: false
    t.uuid "game_id", null: false
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["game_id"], name: "index_used_prompts_on_game_id"
    t.index ["prompt_id"], name: "index_used_prompts_on_prompt_id"
  end

  add_foreign_key "game_states", "games"
  add_foreign_key "game_states", "players"
  add_foreign_key "games", "players", column: "judge_id"
  add_foreign_key "games", "prompts"
  add_foreign_key "prompts", "games"
  add_foreign_key "used_prompts", "games"
  add_foreign_key "used_prompts", "prompts"
end
