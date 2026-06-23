class MonthlyResultAverage < ApplicationRecord
  validates :subject, presence: true
  validates :period, presence: true
  validates :avg_daily_high, :avg_daily_low, presence: true
  validates :result_count, :days_used, presence: true
  validates :subject, uniqueness: { scope: :period }

  scope :for_period, ->(period) { where(period: period) }
end
