FactoryBot.define do
  factory :test_result do
    student_name { Faker::Name.name }
    # Draw from a fixed list so aggregation specs can reliably group by subject.
    subject { %w[Math Science English History].sample }
    marks { Faker::Number.between(from: 0, to: 100) }
    recorded_at { Faker::Time.between(from: 1.day.ago, to: Time.current) }
  end
end
