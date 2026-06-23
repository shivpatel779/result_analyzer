class MonthlyResultAveragesService
  MINIMUM_COUNT = 200

  def call
    return unless run_today?

    subjects = DailyResultStatistic.distinct.pluck(:subject)
    subjects.each { |subject| process_subject(subject) }
  end

  private

  def run_today?
    today = Date.today
    today.monday? && today >= third_wednesday_week_monday(today)
  end

  def third_wednesday_week_monday(date)
    # Find third Wednesday of current month
    first_day = Date.new(date.year, date.month, 1)
    wednesdays = (first_day..first_day.end_of_month).select(&:wednesday?)
    third_wednesday = wednesdays[2]
    third_wednesday.beginning_of_week(:monday)
  end

  def process_subject(subject)
    stats = DailyResultStatistic.for_subject(subject).ordered
    window = collect_window(stats)
    return if window.empty?

    MonthlyResultAverage.create!(
      subject:           subject,
      computed_on:       Date.today,
      avg_daily_high:    window.sum(&:daily_high).to_f / window.size,
      avg_daily_low:     window.sum(&:daily_low).to_f / window.size,
      total_result_count: window.sum(&:result_count),
      days_used:         window.size
    )
  end

  def collect_window(stats)
    window = stats.first(5)
    return window if window.sum(&:result_count) >= MINIMUM_COUNT

    stats.each_with_object([]) do |stat, acc|
      acc << stat
      break acc if acc.sum(&:result_count) >= MINIMUM_COUNT
    end
  end
end
