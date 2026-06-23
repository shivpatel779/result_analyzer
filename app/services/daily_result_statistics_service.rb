class DailyResultStatisticsService
  def initialize(date = Date.yesterday)
    @date = date
  end

  def call
    subjects = TestResult.where(timestamp: @date.all_day).distinct.pluck(:subject)
    subjects.each { |subject| process_subject(subject) }
  end

  private

  def process_subject(subject)
    results = TestResult.where(subject: subject, timestamp: @date.all_day)
    return if results.empty?

    DailyResultStatistic.find_or_initialize_by(date: @date, subject: subject).update!(
      daily_low:    results.minimum(:marks),
      daily_high:   results.maximum(:marks),
      result_count: results.count
    )
  end
end
