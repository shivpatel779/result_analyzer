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

ActiveRecord::Schema[8.1].define(version: 2026_06_22_133848) do
  # These are extensions that must be enabled in order to support this database
  enable_extension "pg_catalog.plpgsql"

  create_table "daily_result_statistics", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "daily_high", null: false
    t.integer "daily_low", null: false
    t.date "date", null: false
    t.integer "result_count", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["date", "subject"], name: "index_daily_result_statistics_on_date_and_subject", unique: true
  end

  create_table "monthly_result_averages", force: :cascade do |t|
    t.decimal "avg_daily_high", precision: 6, scale: 2, null: false
    t.decimal "avg_daily_low", precision: 6, scale: 2, null: false
    t.datetime "created_at", null: false
    t.integer "days_used", null: false
    t.date "period", null: false
    t.integer "result_count", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["subject", "period"], name: "index_monthly_result_averages_on_subject_and_period", unique: true
  end

  create_table "test_results", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "marks", null: false
    t.datetime "recorded_at", null: false
    t.string "student_name", null: false
    t.string "subject", null: false
    t.datetime "updated_at", null: false
    t.index ["recorded_at"], name: "index_test_results_on_recorded_at"
    t.index ["subject", "recorded_at"], name: "index_test_results_on_subject_and_recorded_at"
  end
end
