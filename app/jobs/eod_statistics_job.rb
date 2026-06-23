# End-of-Day job: aggregates the day's TestResults into per-subject statistics.
# Thin wrapper — all logic lives in Eod::CalculateDailyStatistics. Scheduled
# daily at 18:00 via config/recurring.yml.
class EodStatisticsJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    Eod::CalculateDailyStatistics.call(date: date)
  end
end
