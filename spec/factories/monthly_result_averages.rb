FactoryBot.define do
  factory :monthly_result_average do
    subject { %w[Math Science English History].sample }
    period { Date.current }
    avg_daily_high { Faker::Number.between(from: 60, to: 100) }
    avg_daily_low { Faker::Number.between(from: 0, to: 40) }
    result_count { Faker::Number.between(from: 200, to: 500) }
    days_used { Faker::Number.between(from: 5, to: 15) }
  end
end
