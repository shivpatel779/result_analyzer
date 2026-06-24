class MonthlyResultAverage < ApplicationRecord
   validates :computed_on, :subject, presence: true
end
