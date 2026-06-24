require "rails_helper"

RSpec.describe MonthlyAveragesJob, type: :job do
  let(:trigger_monday) { Date.new(2026, 6, 15) }
  let(:non_trigger_day) { Date.new(2026, 6, 16) }

  context "on the trigger date" do
    it "runs the averaging service" do
      expect(Monthly::CalculateAverages).to receive(:call).with(date: trigger_monday)
      described_class.perform_now(date: trigger_monday)
    end
  end

  context "on a non-trigger date" do
    it "does not run the averaging service" do
      expect(Monthly::CalculateAverages).not_to receive(:call)
      described_class.perform_now(date: non_trigger_day)
    end
  end

  it "defaults to the current day and respects the guard" do
    expect(Monthly::CalculateAverages).to receive(:call).with(date: trigger_monday)
    travel_to(trigger_monday) { described_class.perform_now }
  end

  it "produces averages end-to-end when run on the trigger date" do
    5.times { |i| create(:daily_result_statistic, subject: "Math", date: trigger_monday - i, result_count: 40, daily_low: 30, daily_high: 70) }

    expect { described_class.perform_now(date: trigger_monday) }
      .to change(MonthlyResultAverage, :count).by(1)
  end
end
