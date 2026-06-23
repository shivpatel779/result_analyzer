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

ActiveRecord::Schema[8.1].define(version: 2026_06_23_104842) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "daily_result_statistics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "daily_high"
    t.integer "daily_low"
    t.date "date"
    t.integer "result_count"
    t.string "subject"
    t.datetime "updated_at", null: false
  end

  create_table "monthly_result_averages", force: :cascade do |t|
    t.float "avg_daily_high"
    t.float "avg_daily_low"
    t.date "computed_on"
    t.datetime "created_at", null: false
    t.integer "days_used"
    t.integer "total_result_count"
    t.datetime "updated_at", null: false
  end

  create_table "test_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "marks"
    t.string "student_name"
    t.string "subject"
    t.datetime "timestamp"
    t.datetime "updated_at", null: false
  end
end
