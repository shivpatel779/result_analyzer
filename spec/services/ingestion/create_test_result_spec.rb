require "rails_helper"

RSpec.describe Ingestion::CreateTestResult do
  def valid_payload(overrides = {})
    {
      student_name: "Ada Lovelace",
      subject: "Math",
      marks: 87,
      timestamp: "2026-06-22T14:30:00Z"
    }.merge(overrides)
  end

  describe ".call" do
    context "with a valid payload" do
      it "persists a TestResult and reports success" do
        expect { described_class.call(valid_payload) }
          .to change(TestResult, :count).by(1)
      end

      it "maps timestamp onto recorded_at and copies the other fields" do
        result = described_class.call(valid_payload)

        expect(result).to be_success
        record = result.test_result
        expect(record.student_name).to eq("Ada Lovelace")
        expect(record.subject).to eq("Math")
        expect(record.marks).to eq(87)
        expect(record.recorded_at).to eq(Time.utc(2026, 6, 22, 14, 30, 0))
      end

      it "accepts marks supplied as a numeric string" do
        result = described_class.call(valid_payload(marks: "42"))
        expect(result).to be_success
        expect(result.test_result.marks).to eq(42)
      end
    end

    context "with missing fields" do
      %i[student_name subject marks timestamp].each do |field|
        it "fails when #{field} is missing" do
          expect { described_class.call(valid_payload.except(field)) }
            .not_to change(TestResult, :count)
        end
      end

      it "exposes the validation errors" do
        result = described_class.call(valid_payload(student_name: nil))
        expect(result).not_to be_success
        expect(result.errors[:student_name]).to be_present
      end
    end

    context "with invalid marks" do
      it "rejects out-of-range marks" do
        result = described_class.call(valid_payload(marks: 150))
        expect(result).not_to be_success
        expect(result.errors[:marks]).to be_present
      end

      it "rejects non-numeric marks" do
        result = described_class.call(valid_payload(marks: "A+"))
        expect(result).not_to be_success
        expect(result.errors[:marks]).to be_present
      end
    end

    context "with a bad timestamp" do
      it "reports an invalid recorded_at and does not persist" do
        result = nil
        expect { result = described_class.call(valid_payload(timestamp: "not-a-date")) }
          .not_to change(TestResult, :count)
        expect(result).not_to be_success
        expect(result.errors[:recorded_at]).to include("is not a valid timestamp")
      end

      it "treats a blank timestamp as missing (presence error, not parse error)" do
        result = described_class.call(valid_payload(timestamp: ""))
        expect(result).not_to be_success
        expect(result.errors[:recorded_at]).to be_present
        expect(result.errors[:recorded_at]).not_to include("is not a valid timestamp")
      end
    end

    context "with a nil payload" do
      it "fails gracefully without raising" do
        expect { described_class.call(nil) }.not_to raise_error
      end
    end
  end
end
