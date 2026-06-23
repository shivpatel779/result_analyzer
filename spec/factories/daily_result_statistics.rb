FactoryBot.define do
  factory :daily_result_statistic do
    date { "2026-06-23" }
    subject { "MyString" }
    daily_low { 1 }
    daily_high { 1 }
    result_count { 1 }
  end
end
