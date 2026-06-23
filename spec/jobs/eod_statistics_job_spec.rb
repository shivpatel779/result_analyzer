require "rails_helper"

RSpec.describe EodStatisticsJob, type: :job do
  it "delegates to Eod::CalculateDailyStatistics for the given date" do
    date = Date.new(2026, 6, 22)
    expect(Eod::CalculateDailyStatistics).to receive(:call).with(date: date)

    described_class.perform_now(date: date)
  end

  it "defaults to the current day" do
    expect(Eod::CalculateDailyStatistics).to receive(:call).with(date: Date.current)

    described_class.perform_now
  end

  it "actually produces statistics when performed end-to-end" do
    travel_to(Time.zone.local(2026, 6, 22, 12, 0, 0)) do
      create(:test_result, subject: "Math", marks: 40, recorded_at: Time.current)
      create(:test_result, subject: "Math", marks: 80, recorded_at: Time.current)

      expect { described_class.perform_now }.to change(DailyResultStatistic, :count).by(1)
      expect(DailyResultStatistic.find_by(subject: "Math"))
        .to have_attributes(daily_low: 40, daily_high: 80, result_count: 2)
    end
  end
end
