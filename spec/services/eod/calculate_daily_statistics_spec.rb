require "rails_helper"

RSpec.describe Eod::CalculateDailyStatistics do
  # Anchor "today" so recorded_at values are unambiguous.
  let(:today) { Date.new(2026, 6, 22) }
  let(:noon)  { Time.zone.local(2026, 6, 22, 12, 0, 0) }

  def result_for(subject, marks, at: noon)
    create(:test_result, subject: subject, marks: marks, recorded_at: at)
  end

  describe ".call" do
    context "with results across multiple subjects" do
      before do
        result_for("Math", 40)
        result_for("Math", 90)
        result_for("Math", 65)
        result_for("Science", 70)
        result_for("Science", 30)
      end

      it "creates one statistic per subject" do
        expect { described_class.call(date: today) }
          .to change(DailyResultStatistic, :count).by(2)
      end

      it "computes the low, high and count per subject" do
        described_class.call(date: today)

        math = DailyResultStatistic.find_by(date: today, subject: "Math")
        expect(math).to have_attributes(daily_low: 40, daily_high: 90, result_count: 3)

        science = DailyResultStatistic.find_by(date: today, subject: "Science")
        expect(science).to have_attributes(daily_low: 30, daily_high: 70, result_count: 2)
      end
    end

    context "with ties in low and high" do
      it "handles repeated min/max values correctly" do
        result_for("English", 50)
        result_for("English", 50)
        result_for("English", 80)
        result_for("English", 80)

        described_class.call(date: today)

        english = DailyResultStatistic.find_by(date: today, subject: "English")
        expect(english).to have_attributes(daily_low: 50, daily_high: 80, result_count: 4)
      end

      it "treats a single result as both the low and the high" do
        result_for("History", 55)

        described_class.call(date: today)

        history = DailyResultStatistic.find_by(date: today, subject: "History")
        expect(history).to have_attributes(daily_low: 55, daily_high: 55, result_count: 1)
      end
    end

    context "when there are no results for the day" do
      it "creates no statistics and returns an empty collection" do
        # A result on a different day must be ignored.
        result_for("Math", 70, at: Time.zone.local(2026, 6, 21, 12, 0, 0))

        expect { @stats = described_class.call(date: today) }
          .not_to change(DailyResultStatistic, :count)
        expect(@stats).to be_empty
      end
    end

    context "scoping to the target day" do
      it "ignores results recorded on other days" do
        result_for("Math", 10, at: Time.zone.local(2026, 6, 21, 23, 59, 0))
        result_for("Math", 90, at: Time.zone.local(2026, 6, 22, 0, 1, 0))
        result_for("Math", 95, at: Time.zone.local(2026, 6, 23, 0, 1, 0))

        described_class.call(date: today)

        math = DailyResultStatistic.find_by(date: today, subject: "Math")
        expect(math).to have_attributes(daily_low: 90, daily_high: 90, result_count: 1)
      end
    end

    context "idempotency" do
      it "updates rather than duplicates when re-run for the same day" do
        result_for("Math", 40)
        result_for("Math", 60)
        described_class.call(date: today)

        # A late-arriving result, then a re-run.
        result_for("Math", 100)

        expect { described_class.call(date: today) }
          .not_to change(DailyResultStatistic, :count)

        math = DailyResultStatistic.find_by(date: today, subject: "Math")
        expect(math).to have_attributes(daily_low: 40, daily_high: 100, result_count: 3)
      end
    end

    context "without an explicit date" do
      it "defaults to the current day" do
        travel_to(noon) do
          result_for("Math", 75, at: Time.current)
          described_class.call
        end

        expect(DailyResultStatistic.find_by(subject: "Math").date).to eq(today)
      end
    end
  end
end
