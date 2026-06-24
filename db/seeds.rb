# Demo data for local development.
#
# Generates well over 200 TestResults across several days and subjects, then runs
# the EOD and monthly services so every view (and the 200-threshold monthly
# calculation) has realistic data to display. Idempotent: clears its own tables
# on each run.

require "faker"

SUBJECTS = %w[Math Science English History].freeze
DAYS_BACK = 30                 # how many days of history to generate
RESULTS_PER_SUBJECT_PER_DAY = 15

puts "Clearing existing data..."
MonthlyResultAverage.delete_all
DailyResultStatistic.delete_all
TestResult.delete_all

puts "Generating test results (#{DAYS_BACK} days x #{SUBJECTS.size} subjects x #{RESULTS_PER_SUBJECT_PER_DAY})..."
rows = []
DAYS_BACK.times do |day_offset|
  day = Date.current - day_offset
  SUBJECTS.each do |subject|
    RESULTS_PER_SUBJECT_PER_DAY.times do
      recorded_at = Time.zone.local(day.year, day.month, day.day,
                                    rand(0..23), rand(0..59), rand(0..59))
      rows << {
        student_name: Faker::Name.name,
        subject: subject,
        marks: Faker::Number.between(from: 0, to: 100),
        recorded_at: recorded_at,
        created_at: Time.current,
        updated_at: Time.current
      }
    end
  end
end
TestResult.insert_all!(rows)
puts "  -> #{TestResult.count} test results created."

puts "Running EOD statistics for each day..."
DAYS_BACK.times do |day_offset|
  Eod::CalculateDailyStatistics.call(date: Date.current - day_offset)
end
puts "  -> #{DailyResultStatistic.count} daily statistics created."

puts "Running monthly averages for the most recent trigger Monday..."
trigger = Monthly::TriggerDate.trigger_for(Date.current)
trigger = Monthly::TriggerDate.trigger_for(Date.current.prev_month) if trigger > Date.current
Monthly::CalculateAverages.call(date: trigger)
puts "  -> #{MonthlyResultAverage.count} monthly averages created for period #{trigger}."

puts "Done."
