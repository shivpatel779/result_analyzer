require "rails_helper"

RSpec.describe Monthly::CalculateAverages do
  # Explicit values throughout (no Faker) so the 200-threshold boundaries and
  # averages are exact and deterministic.
  def stat(subject, date, low:, high:, count:)
    create(:daily_result_statistic,
           subject: subject, date: date,
           daily_low: low, daily_high: high, result_count: count)
  end

  # Create `n` consecutive statistic-days for `subject` ending at `anchor`
  # (anchor, anchor-1, ...), each with the same low/high/count.
  def consecutive(subject, anchor, n, low:, high:, count:)
    n.times { |i| stat(subject, anchor - i, low: low, high: high, count: count) }
  end

  def average_for(subject, period)
    MonthlyResultAverage.find_by(subject: subject, period: period)
  end

  let(:anchor) { Date.new(2026, 6, 15) } # a June trigger Monday

  describe ".call" do
    context "when the most recent 5 days already total exactly 200" do
      it "uses exactly those 5 days" do
        # 5 days * 40 = 200.
        stat("Math", anchor,     low: 10, high: 90, count: 40)
        stat("Math", anchor - 1, low: 20, high: 80, count: 40)
        stat("Math", anchor - 2, low: 30, high: 70, count: 40)
        stat("Math", anchor - 3, low: 40, high: 60, count: 40)
        stat("Math", anchor - 4, low: 50, high: 50, count: 40)
        # An older day that must NOT be consumed (threshold already met at 5 days).
        stat("Math", anchor - 5, low: 0, high: 100, count: 100)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(5)
        expect(avg.result_count).to eq(200)
        expect(avg.avg_daily_high).to eq(70)   # (90+80+70+60+50)/5
        expect(avg.avg_daily_low).to eq(30)    # (10+20+30+40+50)/5
      end
    end

    context "when the most recent 5 days fall just under 200" do
      it "extends further back until the threshold is reached" do
        # 5 days * 39 = 195 (< 200), then one more day of 10 -> 205.
        consecutive("Math", anchor, 5, low: 20, high: 80, count: 39)
        stat("Math", anchor - 5, low: 20, high: 80, count: 10)
        # Still more history that should be untouched once 200 is crossed.
        stat("Math", anchor - 6, low: 0, high: 100, count: 100)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(6)
        expect(avg.result_count).to eq(205)
        expect(avg.avg_daily_high).to eq(80)
        expect(avg.avg_daily_low).to eq(20)
      end
    end

    context "when the most recent 5 days are well over 200" do
      it "still stops at the minimum 5-day window" do
        # 5 days * 100 = 500 (well over 200); a 6th day exists but is excluded.
        consecutive("Math", anchor, 5, low: 25, high: 75, count: 100)
        stat("Math", anchor - 5, low: 0, high: 100, count: 100)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(5)
        expect(avg.result_count).to eq(500)
      end
    end

    context "when the lookback crosses a month boundary" do
      let(:july_anchor) { Date.new(2026, 7, 3) }

      it "consumes days from the previous month" do
        # 3 days in July + days in June, 30 each. Need >= 200 -> 7 days (210).
        consecutive("Math", july_anchor, 3, low: 10, high: 90, count: 30) # Jul 3,2,1
        consecutive("Math", Date.new(2026, 6, 30), 4, low: 10, high: 90, count: 30) # Jun 30..27

        described_class.call(date: july_anchor)

        avg = average_for("Math", july_anchor)
        expect(avg.days_used).to eq(7)
        expect(avg.result_count).to eq(210)
        # The window genuinely reaches back into June.
        consumed = DailyResultStatistic.for_subject("Math")
          .where(date: ..july_anchor).recent_first.limit(avg.days_used).pluck(:date)
        expect(consumed.map(&:month)).to include(6)
      end
    end

    context "with insufficient history (never reaches 200)" do
      it "uses every available day and records the actual (sub-threshold) count" do
        stat("Math", anchor,     low: 30, high: 70, count: 20)
        stat("Math", anchor - 1, low: 40, high: 60, count: 20)
        stat("Math", anchor - 2, low: 50, high: 50, count: 20)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(3)
        expect(avg.result_count).to eq(60)
        expect(avg.avg_daily_high).to eq(60)
        expect(avg.avg_daily_low).to eq(40)
      end
    end

    context "with fewer than 5 days of history, even when already over 200" do
      it "uses every available day (the window can be smaller than the 5-day minimum)" do
        # Only 3 statistic-days exist; 3 * 100 = 300 (>= 200), but the 5-day
        # minimum can't be met, so the loop ends when history runs out.
        consecutive("Math", anchor, 3, low: 25, high: 75, count: 100)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(3)
        expect(avg.result_count).to eq(300)
      end
    end

    context "with exactly 5 days of sub-threshold history" do
      it "uses all 5 days and records the actual (sub-threshold) count" do
        # 5 days * 30 = 150 (< 200) and no older history -> all 5 days used.
        consecutive("Math", anchor, 5, low: 20, high: 80, count: 30)

        described_class.call(date: anchor)

        avg = average_for("Math", anchor)
        expect(avg.days_used).to eq(5)
        expect(avg.result_count).to eq(150)
        expect(avg.avg_daily_high).to eq(80)
        expect(avg.avg_daily_low).to eq(20)
      end
    end

    context "when a subject's only statistics fall after the run date" do
      it "produces no row for that subject" do
        # "Future" has data only after the anchor; "Math" has valid history.
        stat("Future", anchor + 1, low: 0, high: 100, count: 500)
        consecutive("Math", anchor, 5, low: 30, high: 70, count: 40)

        described_class.call(date: anchor)

        expect(average_for("Future", anchor)).to be_nil
        expect(MonthlyResultAverage.pluck(:subject)).to contain_exactly("Math")
      end
    end

    context "with multiple subjects" do
      it "computes each subject independently" do
        consecutive("Math", anchor, 5, low: 30, high: 70, count: 40)    # 200
        consecutive("Science", anchor, 5, low: 10, high: 90, count: 50) # 250

        records = described_class.call(date: anchor)
        expect(records.size).to eq(2)

        expect(average_for("Math", anchor)).to have_attributes(result_count: 200, days_used: 5)
        expect(average_for("Science", anchor)).to have_attributes(result_count: 250, days_used: 5)
      end
    end

    context "rounding" do
      it "rounds averages to two decimal places" do
        stat("Math", anchor,     low: 10, high: 90, count: 50)
        stat("Math", anchor - 1, low: 10, high: 80, count: 50)
        stat("Math", anchor - 2, low: 10, high: 70, count: 50)
        stat("Math", anchor - 3, low: 10, high: 60, count: 50)
        stat("Math", anchor - 4, low: 10, high: 52, count: 50) # highs sum 352 / 5 = 70.4

        described_class.call(date: anchor)

        expect(average_for("Math", anchor).avg_daily_high).to eq(BigDecimal("70.4"))
      end
    end

    context "anchoring" do
      it "ignores statistic-days after the run date" do
        stat("Math", anchor + 1, low: 0, high: 100, count: 999) # future, must be ignored
        consecutive("Math", anchor, 5, low: 30, high: 70, count: 40)

        described_class.call(date: anchor)

        expect(average_for("Math", anchor).result_count).to eq(200)
      end
    end

    context "when there are no statistics" do
      it "creates no records and returns an empty collection" do
        expect(described_class.call(date: anchor)).to be_empty
        expect(MonthlyResultAverage.count).to eq(0)
      end
    end

    context "idempotency" do
      it "updates rather than duplicates on re-run" do
        consecutive("Math", anchor, 5, low: 30, high: 70, count: 40)
        described_class.call(date: anchor)

        # A late day arrives, then a re-run for the same period.
        stat("Math", anchor - 5, low: 0, high: 100, count: 10)

        expect { described_class.call(date: anchor) }
          .not_to change(MonthlyResultAverage, :count)
      end
    end
  end
end
