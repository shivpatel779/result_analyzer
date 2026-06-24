class DashboardController < ApplicationController
  def index
    @test_results = TestResult.order(recorded_at: :desc).limit(50)
    @total_count = TestResult.count
  end
end
