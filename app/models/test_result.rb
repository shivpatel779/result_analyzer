# A single student's test result as delivered by the third-party MSM service.
# This is the raw source of truth that the EOD and monthly jobs aggregate over.
class TestResult < ApplicationRecord
  # Marks are stored as an integer percentage score. See README for the assumption.
  MARKS_RANGE = 0..100

  validates :student_name, presence: true
  validates :subject, presence: true
  validates :recorded_at, presence: true
  validates :marks,
            presence: true,
            numericality: {
              only_integer: true,
              greater_than_or_equal_to: MARKS_RANGE.min,
              less_than_or_equal_to: MARKS_RANGE.max
            }

  # Results recorded on a given calendar day (in the application time zone).
  scope :recorded_on, ->(date) {
    day = date.to_date
    where(recorded_at: day.all_day)
  }
end
