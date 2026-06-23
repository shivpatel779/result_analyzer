class CreateMonthlyResultAverages < ActiveRecord::Migration[8.1]
  def change
    create_table :monthly_result_averages do |t|
      t.date :computed_on
      t.float :avg_daily_high
      t.float :avg_daily_low
      t.integer :total_result_count
      t.integer :days_used

      t.timestamps
    end
  end
end
