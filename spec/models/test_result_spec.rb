require "rails_helper"

RSpec.describe TestResult, type: :model do
  describe "factory" do
    it "builds a valid record" do
      expect(build(:test_result)).to be_valid
    end
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:student_name) }
    it { is_expected.to validate_presence_of(:subject) }
    it { is_expected.to validate_presence_of(:recorded_at) }
    it { is_expected.to validate_presence_of(:marks) }

    # Marks are an integer percentage in 0..100 (boundaries inclusive, no floats).
    it {
      is_expected.to validate_numericality_of(:marks)
        .only_integer
        .is_greater_than_or_equal_to(0)
        .is_less_than_or_equal_to(100)
    }
  end

  describe ".recorded_on" do
    around { |example| travel_to(Time.zone.local(2026, 6, 22, 12, 0, 0)) { example.run } }

    it "returns only results recorded on the given calendar day" do
      today_morning = create(:test_result, recorded_at: Time.zone.local(2026, 6, 22, 8, 0, 0))
      today_evening = create(:test_result, recorded_at: Time.zone.local(2026, 6, 22, 23, 59, 0))
      _yesterday = create(:test_result, recorded_at: Time.zone.local(2026, 6, 21, 23, 0, 0))
      _tomorrow = create(:test_result, recorded_at: Time.zone.local(2026, 6, 23, 0, 1, 0))

      expect(described_class.recorded_on(Date.new(2026, 6, 22)))
        .to match_array([today_morning, today_evening])
    end
  end
end
