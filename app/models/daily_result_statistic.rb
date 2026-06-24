class DailyResultStatistic < ApplicationRecord
   validates :date, :subject, presence: true
  scope :for_subject, ->(subject) { where(subject: subject) }
  scope :ordered, -> { order(date: :desc) }
end
