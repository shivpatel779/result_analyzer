FactoryBot.define do
  factory :monthly_result_average do
    computed_on { "2026-06-23" }
    avg_daily_high { 1.5 }
    avg_daily_low { 1.5 }
    total_result_count { 1 }
    days_used { 1 }
  end
end
