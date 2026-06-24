require "rails_helper"

# End-to-end: drives the three features together with no mocks —
# HTTP ingestion -> EOD daily-statistics job -> monthly-averages job — and
# checks that the final MonthlyResultAverage matches a hand-computed value.
RSpec.describe "Result analysis pipeline", type: :request do
  # June 15, 2026 is the Monday of the week containing the third Wednesday
  # (June 17). Derived from the resolver so the date can't drift.
  let(:trigger_monday) { Monthly::TriggerDate.trigger_for(Date.new(2026, 6, 1)) }

  # Ingest one result over HTTP, exactly as MSM would.
  def ingest(subject:, marks:, on:)
    post "/api/test_results", params: {
      student_name: "Student #{marks}",
      subject: subject,
      marks: marks,
      timestamp: Time.zone.local(on.year, on.month, on.day, 12, 0).iso8601
    }
  end

  # Build a day of results then run the real EOD job for that day.
  def aggregate_day(subject:, date:, marks:)
    marks.each { |m| ingest(subject: subject, marks: m, on: date) }
    EodStatisticsJob.perform_now(date: date)
  end

  # Five days of "Math" history, ending on the trigger Monday. Highs/lows are
  # chosen so the averages are exact. History totals 11 results (< 200), so the
  # lookback uses all five available days.
  def build_history
    aggregate_day(subject: "Math", date: trigger_monday,     marks: [50, 80, 60]) # low 50, high 80, n 3
    aggregate_day(subject: "Math", date: trigger_monday - 1, marks: [40, 90])     # low 40, high 90, n 2
    aggregate_day(subject: "Math", date: trigger_monday - 2, marks: [30, 70])     # low 30, high 70, n 2
    aggregate_day(subject: "Math", date: trigger_monday - 3, marks: [20, 100])    # low 20, high 100, n 2
    aggregate_day(subject: "Math", date: trigger_monday - 4, marks: [10, 60])     # low 10, high 60, n 2
  end

  it "ingests results, aggregates them at EOD, and produces the monthly average" do
    # --- Stage 1: ingestion returns 201 and EOD aggregates the latest day ---
    aggregate_day(subject: "Math", date: trigger_monday, marks: [50, 80, 60])
    expect(response).to have_http_status(:created)

    latest = DailyResultStatistic.find_by(subject: "Math", date: trigger_monday)
    expect(latest).to have_attributes(daily_low: 50, daily_high: 80, result_count: 3)

    # --- Stage 2: build the rest of the history ---
    aggregate_day(subject: "Math", date: trigger_monday - 1, marks: [40, 90])
    aggregate_day(subject: "Math", date: trigger_monday - 2, marks: [30, 70])
    aggregate_day(subject: "Math", date: trigger_monday - 3, marks: [20, 100])
    aggregate_day(subject: "Math", date: trigger_monday - 4, marks: [10, 60])
    expect(DailyResultStatistic.where(subject: "Math").count).to eq(5)

    # --- Stage 3: monthly job runs on the trigger Monday ---
    MonthlyAveragesJob.perform_now(date: trigger_monday)

    avg = MonthlyResultAverage.find_by(subject: "Math", period: trigger_monday)
    expect(avg).to have_attributes(
      days_used: 5,
      result_count: 11,             # 3 + 2 + 2 + 2 + 2
      avg_daily_high: 80,           # (80 + 90 + 70 + 100 + 60) / 5
      avg_daily_low: 30             # (50 + 40 + 30 + 20 + 10) / 5
    )
  end

  it "does not produce monthly averages when run on a non-trigger day" do
    build_history

    expect {
      MonthlyAveragesJob.perform_now(date: trigger_monday - 1)
    }.not_to change(MonthlyResultAverage, :count).from(0)
  end
end
