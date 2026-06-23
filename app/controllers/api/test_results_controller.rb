module Api
  # Ingestion endpoint for the third-party MSM service.
  #
  # Inherits from ActionController::API: this is a token-free JSON endpoint
  # (see README for the no-auth assumption) and does not need CSRF protection
  # or view/cookie middleware.
  class TestResultsController < ActionController::API
    def create
      result = Ingestion::CreateTestResult.call(test_result_params)

      if result.success?
        render json: serialize(result.test_result), status: :created
      else
        render json: { errors: result.errors.to_hash(true) }, status: :unprocessable_content
      end
    end

    private

    # MSM sends a flat JSON body; permit its known fields. params.expect would be
    # too strict for an external integration, so we permit defensively.
    def test_result_params
      params.permit(:student_name, :subject, :marks, :timestamp).to_h
    end

    def serialize(test_result)
      {
        id: test_result.id,
        student_name: test_result.student_name,
        subject: test_result.subject,
        marks: test_result.marks,
        recorded_at: test_result.recorded_at&.iso8601
      }
    end
  end
end
