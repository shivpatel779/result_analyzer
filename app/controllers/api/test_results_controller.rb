class Api::TestResultsController < ApplicationController
  skip_before_action :verify_authenticity_token

  def index
    results = TestResult.all
    render json: { result: results }, status: :ok
  end

  def create
    result = TestResult.new(test_result_params)
    if result.save
      render json: { message: "Result received", id: result.id }, status: :created
    else
      render json: { errors: result.errors.full_messages }, status: :unprocessable_entity
    end
  end

  def show
    result = TestResult.find_by(id: params[:id])
    if result
      render json: result, status: :ok
    else
      render json: { error: "Not found" }, status: :not_found
    end
  end

  private

  def test_result_params
    params.require(:test_result).permit(:student_name, :subject, :marks, :timestamp)
  end
end