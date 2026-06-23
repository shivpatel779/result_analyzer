module Eod
  # Builds one DailyResultStatistic per subject for a given day by aggregating
  # that day's TestResults (lowest mark, highest mark, count).
  #
  # Idempotent: re-running for the same day upserts the existing rows rather than
  # duplicating them. A day with no results produces no rows (see README).
  class CalculateDailyStatistics
    def self.call(date: Date.current)
      new(date: date).call
    end

    def initialize(date: Date.current)
      @date = date.to_date
    end

    def call
      aggregates = TestResult
        .recorded_on(@date)
        .group(:subject)
        .pluck(:subject, Arel.sql("MIN(marks)"), Arel.sql("MAX(marks)"), Arel.sql("COUNT(*)"))

      aggregates.map do |subject, low, high, count|
        upsert_statistic(subject:, low:, high:, count:)
      end
    end

    private

    def upsert_statistic(subject:, low:, high:, count:)
      stat = DailyResultStatistic.find_or_initialize_by(date: @date, subject: subject)
      stat.update!(daily_low: low, daily_high: high, result_count: count)
      stat
    end
  end
end
