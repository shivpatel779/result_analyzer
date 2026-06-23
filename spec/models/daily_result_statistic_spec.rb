require "rails_helper"

RSpec.describe DailyResultStatistic, type: :model do
  subject { build(:daily_result_statistic) }

  describe "factory" do
    it "builds a valid record" do
      expect(build(:daily_result_statistic)).to be_valid
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:date) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:daily_low) }
    it { is_expected.to validate_presence_of(:daily_high) }
    it { is_expected.to validate_presence_of(:result_count) }
    it { is_expected.to validate_uniqueness_of(:subject).scoped_to(:date) }

    it "rejects a daily_low greater than daily_high" do
      expect(build(:daily_result_statistic, daily_low: 90, daily_high: 10)).not_to be_valid
    end

    it "allows daily_low equal to daily_high (a single result / a tie)" do
      expect(build(:daily_result_statistic, daily_low: 70, daily_high: 70)).to be_valid
    end
  end

  describe "scopes" do
    it ".recent_first orders by date descending" do
      old = create(:daily_result_statistic, date: Date.new(2026, 6, 20), subject: "Math")
      new = create(:daily_result_statistic, date: Date.new(2026, 6, 22), subject: "Math")
      expect(described_class.recent_first.to_a).to eq([new, old])
    end
  end
end
