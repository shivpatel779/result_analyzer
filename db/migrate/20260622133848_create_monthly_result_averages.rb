class CreateMonthlyResultAverages < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_result_averages do |t|
      t.string :subject, null: false
      t.date :period, null: false # the trigger Monday the calculation was run for
      t.decimal :avg_daily_high, precision: 6, scale: 2, null: false
      t.decimal :avg_daily_low, precision: 6, scale: 2, null: false
      t.integer :result_count, null: false # total results used in the calculation
      t.integer :days_used, null: false    # number of DailyResultStatistic days consumed

      t.timestamps
    end

    # One average per subject per run; also the upsert conflict target.
    add_index :monthly_result_averages, %i[subject period], unique: true
  end
end
