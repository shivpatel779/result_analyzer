module Monthly
  # Computes per-subject monthly averages from DailyResultStatistic rows.
  #
  # For each subject, walk statistic-days backwards from the most recent (on or
  # before +date+). Start with the most recent 5 days; if their cumulative
  # result_count is below THRESHOLD, keep extending further back — across month
  # boundaries if necessary (see README) — until the cumulative count reaches the
  # threshold or history runs out. Then average the daily highs and lows over the
  # window and persist one MonthlyResultAverage per subject (idempotent upsert).
  class CalculateAverages
    THRESHOLD = 200
    INITIAL_DAYS = 5

    def self.call(date: Date.current)
      new(date: date).call
    end

    def initialize(date: Date.current)
      @date = date.to_date
    end

    def call
      subjects.map { |subject| calculate_for(subject) }.compact
    end

    private

    attr_reader :date

    def subjects
      DailyResultStatistic.where(date: ..date).distinct.pluck(:subject)
    end

    def calculate_for(subject)
      window = lookback_window(subject)
      return if window.empty?

      days_used = window.size
      total_count = window.sum(&:result_count)

      upsert(
        subject: subject,
        avg_daily_high: average(window.sum(&:daily_high), days_used),
        avg_daily_low: average(window.sum(&:daily_low), days_used),
        result_count: total_count,
        days_used: days_used
      )
    end

    # The statistic-days, most recent first, that the calculation consumes.
    def lookback_window(subject)
      rows = DailyResultStatistic
        .for_subject(subject)
        .where(date: ..date)
        .recent_first
        .to_a

      selected = []
      cumulative = 0
      rows.each do |row|
        selected << row
        cumulative += row.result_count
        break if selected.size >= INITIAL_DAYS && cumulative >= THRESHOLD
      end
      selected
    end

    def average(sum, count)
      (sum.to_d / count).round(2)
    end

    def upsert(subject:, **attributes)
      record = MonthlyResultAverage.find_or_initialize_by(subject: subject, period: date)
      record.update!(**attributes)
      record
    end
  end
end
