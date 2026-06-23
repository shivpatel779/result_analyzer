class TestResult < ApplicationRecord
    validates :student_name, :subject, :marks, :timestamp, presence: true
end
