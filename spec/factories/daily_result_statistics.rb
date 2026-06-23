FactoryBot.define do
  factory :daily_result_statistic do
    date { Date.current }
    subject { %w[Math Science English History].sample }
    daily_low { Faker::Number.between(from: 0, to: 50) }
    daily_high { Faker::Number.between(from: 51, to: 100) }
    result_count { Faker::Number.between(from: 1, to: 80) }
  end
end
