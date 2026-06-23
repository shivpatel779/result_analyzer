# Per-subject aggregate of a single day's TestResults, produced by the EOD job.
class DailyResultStatistic < ApplicationRecord
  validates :date, presence: true
  validates :subject, presence: true
  validates :daily_low, :daily_high, :result_count, presence: true
  validates :subject, uniqueness: { scope: :date }
  validate :low_not_greater_than_high

  scope :for_subject, ->(subject) { where(subject: subject) }
  # Most recent days first — the starting point for the monthly lookback.
  scope :recent_first, -> { order(date: :desc) }

  private

  def low_not_greater_than_high
    return if daily_low.blank? || daily_high.blank?

    errors.add(:daily_low, "must be less than or equal to daily_high") if daily_low > daily_high
  end
end
