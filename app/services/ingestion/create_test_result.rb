module Ingestion
  # Validates and persists a single test result delivered by the MSM service.
  #
  # The incoming payload uses MSM's field names (notably +timestamp+), which this
  # service maps onto the TestResult schema (+recorded_at+). All failures —
  # missing fields, out-of-range marks, an unparseable timestamp — surface as
  # validation errors on the returned result rather than as raised exceptions.
  #
  #   result = Ingestion::CreateTestResult.call(payload)
  #   result.success?    # => true / false
  #   result.test_result # => the persisted (or unsaved) TestResult
  #   result.errors      # => ActiveModel::Errors
  class CreateTestResult
    Result = Struct.new(:success, :test_result, :errors, keyword_init: true) do
      def success? = success
    end

    def self.call(payload)
      new(payload).call
    end

    def initialize(payload)
      @payload = (payload || {}).to_h.with_indifferent_access
    end

    def call
      test_result = TestResult.new(
        student_name: payload[:student_name],
        subject: payload[:subject],
        marks: payload[:marks],
        recorded_at: parse_timestamp(payload[:timestamp])
      )

      # A timestamp that was present but unparseable is reported explicitly so the
      # client can distinguish "missing" from "malformed".
      if timestamp_present_but_invalid?
        test_result.errors.add(:recorded_at, "is not a valid timestamp")
      end

      saved = test_result.errors.empty? && test_result.save

      Result.new(success: saved, test_result: test_result, errors: test_result.errors)
    end

    private

    attr_reader :payload

    def parse_timestamp(value)
      return nil if value.blank?

      Time.zone.parse(value.to_s)
    rescue ArgumentError
      nil
    end

    def timestamp_present_but_invalid?
      payload[:timestamp].present? && parse_timestamp(payload[:timestamp]).nil?
    end
  end
end
