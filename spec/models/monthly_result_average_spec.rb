require "rails_helper"

RSpec.describe MonthlyResultAverage, type: :model do
  subject { build(:monthly_result_average) }

  it "has a valid factory" do
    expect(build(:monthly_result_average)).to be_valid
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:period) }
    it { is_expected.to validate_presence_of(:avg_daily_high) }
    it { is_expected.to validate_presence_of(:avg_daily_low) }
    it { is_expected.to validate_presence_of(:result_count) }
    it { is_expected.to validate_presence_of(:days_used) }
    it { is_expected.to validate_uniqueness_of(:subject).scoped_to(:period) }
  end
end
