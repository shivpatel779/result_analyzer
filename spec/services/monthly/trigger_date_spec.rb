require "rails_helper"

RSpec.describe Monthly::TriggerDate do
  # Across 2026 the 1st of the month lands on every weekday, so this table
  # exercises all alignment cases (including months whose 1st *is* a Wednesday,
  # where the first Wednesday is the 1st). Values are precomputed by hand.
  #
  # [year, month] => [third Wednesday, trigger Monday]
  EXPECTED = {
    [2026,  1] => [Date.new(2026,  1, 21), Date.new(2026,  1, 19)], # 1st = Thu
    [2026,  2] => [Date.new(2026,  2, 18), Date.new(2026,  2, 16)], # 1st = Sun
    [2026,  3] => [Date.new(2026,  3, 18), Date.new(2026,  3, 16)], # 1st = Sun
    [2026,  4] => [Date.new(2026,  4, 15), Date.new(2026,  4, 13)], # 1st = Wed
    [2026,  5] => [Date.new(2026,  5, 20), Date.new(2026,  5, 18)], # 1st = Fri
    [2026,  6] => [Date.new(2026,  6, 17), Date.new(2026,  6, 15)], # 1st = Mon
    [2026,  7] => [Date.new(2026,  7, 15), Date.new(2026,  7, 13)], # 1st = Wed
    [2026,  8] => [Date.new(2026,  8, 19), Date.new(2026,  8, 17)], # 1st = Sat
    [2026,  9] => [Date.new(2026,  9, 16), Date.new(2026,  9, 14)], # 1st = Tue
    [2026, 10] => [Date.new(2026, 10, 21), Date.new(2026, 10, 19)], # 1st = Thu
    [2026, 11] => [Date.new(2026, 11, 18), Date.new(2026, 11, 16)], # 1st = Sun
    [2026, 12] => [Date.new(2026, 12, 16), Date.new(2026, 12, 14)]  # 1st = Tue
  }.freeze

  describe ".third_wednesday and .trigger_for" do
    EXPECTED.each do |(year, month), (third_wed, monday)|
      context "for #{Date.new(year, month, 1).strftime('%B %Y')} (1st is a #{Date.new(year, month, 1).strftime('%A')})" do
        let(:any_day_in_month) { Date.new(year, month, 10) }

        it "identifies the third Wednesday as #{third_wed}" do
          result = described_class.third_wednesday(any_day_in_month)
          expect(result).to eq(third_wed)
          expect(result.wednesday?).to be(true)
        end

        it "resolves the trigger Monday to #{monday}" do
          result = described_class.trigger_for(any_day_in_month)
          expect(result).to eq(monday)
          expect(result.monday?).to be(true)
        end

        it "places the trigger Monday two days before the third Wednesday, same month" do
          expect(monday + 2).to eq(third_wed)
          expect(monday.month).to eq(month)
        end
      end
    end
  end

  describe ".run_today?" do
    let(:monday) { Date.new(2026, 6, 15) } # June 2026 trigger Monday

    it "is true on the trigger Monday" do
      expect(described_class.run_today?(monday)).to be(true)
    end

    it "is false the day before (Sunday)" do
      expect(described_class.run_today?(monday - 1)).to be(false)
    end

    it "is false the day after (Tuesday)" do
      expect(described_class.run_today?(monday + 1)).to be(false)
    end

    it "is false on the third Wednesday itself" do
      expect(described_class.run_today?(Date.new(2026, 6, 17))).to be(false)
    end

    it "is false on a Monday that is not the trigger Monday" do
      expect(described_class.run_today?(Date.new(2026, 6, 8))).to be(false)
    end

    it "defaults to Date.current" do
      travel_to(monday) { expect(described_class.run_today?).to be(true) }
    end
  end
end
