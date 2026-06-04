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

ActiveRecord::Schema[7.2].define(version: 2026_06_04_000000) do
  create_table "rake_task_executions", force: :cascade do |t|
    t.string "task_name", limit: 255, null: false
    t.text "arguments"
    t.datetime "started_at", null: false
    t.datetime "finished_at", null: false
    t.bigint "duration_ms"
    t.string "status", limit: 20, null: false
    t.string "error_class", limit: 255
    t.text "error_message"
    t.string "hostname", limit: 255
    t.integer "pid"
    t.string "ruby_version", limit: 50
    t.string "rails_env", limit: 50
    t.datetime "created_at", null: false
    t.datetime "updated_at", null: false
    t.index ["hostname"], name: "index_rake_task_executions_on_hostname"
    t.index ["started_at"], name: "index_rake_task_executions_on_started_at"
    t.index ["status", "started_at"], name: "index_rake_task_executions_on_status_and_started_at"
    t.index ["status"], name: "index_rake_task_executions_on_status"
    t.index ["task_name", "started_at"], name: "index_rake_task_executions_on_task_name_and_started_at"
    t.index ["task_name"], name: "index_rake_task_executions_on_task_name"
  end
end
