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

ActiveRecord::Schema[8.1].define(version: 2026_03_08_223049) do
  create_table "configs", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "settings"
    t.string "type", default: "Config", null: false
    t.datetime "updated_at", null: false
  end

  create_table "upload_sessions", id: :string, force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "destination_path"
    t.text "error_message"
    t.bigint "file_size"
    t.string "filename", null: false
    t.string "mime_type"
    t.integer "received_chunks", default: 0, null: false
    t.string "status", default: "pending", null: false
    t.integer "total_chunks", null: false
    t.datetime "updated_at", null: false
  end
end
