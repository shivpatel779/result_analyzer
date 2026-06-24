require "rails_helper"

# These specs exercise the thin HTML controllers through the full request stack,
# asserting the data, ordering, grouping, and limits the controllers prepare —
# not just that the page renders. Ordering is checked by comparing the positions
# of unique markers within the rendered body.
RSpec.describe "HTML pages", type: :request do
  def body_index(text)
    response.body.index(text) || raise("expected #{text.inspect} in response body")
  end

  describe "GET / (dashboard)" do
    it "lists the most recent results first" do
      create(:test_result, student_name: "Older Student",  recorded_at: 3.days.ago)
      create(:test_result, student_name: "Newer Student",  recorded_at: 1.hour.ago)

      get root_path

      expect(response).to have_http_status(:ok)
      expect(body_index("Newer Student")).to be < body_index("Older Student")
    end

    it "shows at most the 50 most recent results" do
      # 51 results, oldest -> newest. Zero-padded names avoid substring collisions
      # (e.g. "Student050" is not a substring of "Student005").
      51.times do |i|
        create(:test_result,
               student_name: "Student#{format('%03d', i)}",
               marks: 70,
               recorded_at: (i + 1).hours.ago)
      end

      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("Student000")      # most recent, kept
      expect(response.body).not_to include("Student050")  # 51st oldest, dropped by the limit
    end

    it "renders the total result count" do
      create_list(:test_result, 8, marks: 70, recorded_at: Time.zone.local(2026, 6, 20, 9, 5))

      get root_path

      # The total is the big stat directly above the "Total results" label.
      expect(response.body).to match(
        %r{>\s*8\s*</div>\s*<div class="text-xs uppercase tracking-wide text-slate-500">\s*Total results}m
      )
    end

    it "renders an empty state with no data" do
      get root_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No test results yet")
    end
  end

  describe "GET /daily_statistics" do
    it "groups by date, most recent date first" do
      create(:daily_result_statistic, subject: "Math", date: Date.new(2026, 6, 20))
      create(:daily_result_statistic, subject: "Math", date: Date.new(2026, 6, 22))

      get daily_statistics_path

      expect(response).to have_http_status(:ok)
      expect(body_index("June 22, 2026")).to be < body_index("June 20, 2026")
    end

    it "orders subjects alphabetically within a date" do
      date = Date.new(2026, 6, 22)
      create(:daily_result_statistic, subject: "Zoology", date: date)
      create(:daily_result_statistic, subject: "Algebra", date: date)

      get daily_statistics_path

      expect(body_index("Algebra")).to be < body_index("Zoology")
    end

    it "renders an empty state with no data" do
      get daily_statistics_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No daily statistics yet")
    end
  end

  describe "GET /monthly_averages" do
    it "orders by period descending, then subject ascending, and renders 2-decimal averages" do
      create(:monthly_result_average, subject: "Zoology", period: Date.new(2026, 5, 18))
      create(:monthly_result_average, subject: "Math",    period: Date.new(2026, 6, 15),
             avg_daily_high: 70.4, avg_daily_low: 30.5)
      create(:monthly_result_average, subject: "Art",     period: Date.new(2026, 6, 15))

      get monthly_averages_path

      expect(response).to have_http_status(:ok)
      # Newer period (June) before older (May); within June, Art before Math.
      expect(body_index("Art")).to be < body_index("Math")
      expect(body_index("Math")).to be < body_index("Zoology")
      # Averages rendered to two decimals.
      expect(response.body).to include("70.40").and include("30.50")
    end

    it "renders an empty state with no data" do
      get monthly_averages_path

      expect(response).to have_http_status(:ok)
      expect(response.body).to include("No monthly averages yet")
    end
  end
end
