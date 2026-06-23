require "rails_helper"

RSpec.describe "POST /api/test_results", type: :request do
  def post_result(payload)
    post "/api/test_results", params: payload.to_json,
                              headers: { "Content-Type" => "application/json" }
  end

  let(:valid_payload) do
    {
      student_name: "Grace Hopper",
      subject: "Science",
      marks: 95,
      timestamp: "2026-06-22T09:15:00Z"
    }
  end

  context "with a valid payload" do
    it "creates a record and returns 201 with the persisted result" do
      expect { post_result(valid_payload) }.to change(TestResult, :count).by(1)

      expect(response).to have_http_status(:created)
      body = response.parsed_body
      expect(body["id"]).to be_present
      expect(body["student_name"]).to eq("Grace Hopper")
      expect(body["subject"]).to eq("Science")
      expect(body["marks"]).to eq(95)
      expect(body["recorded_at"]).to eq("2026-06-22T09:15:00Z")
    end
  end

  context "with a missing field" do
    it "returns 422 with errors and persists nothing" do
      expect { post_result(valid_payload.except(:subject)) }
        .not_to change(TestResult, :count)

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("subject")
    end
  end

  context "with out-of-range marks" do
    it "returns 422" do
      post_result(valid_payload.merge(marks: 250))

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("marks")
    end
  end

  context "with a bad timestamp" do
    it "returns 422 with a recorded_at error" do
      post_result(valid_payload.merge(timestamp: "yesterday-ish"))

      expect(response).to have_http_status(:unprocessable_content)
      expect(response.parsed_body["errors"]).to have_key("recorded_at")
    end
  end
end
