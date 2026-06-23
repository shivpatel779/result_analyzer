class EodProcessingJob < ApplicationJob
  queue_as :default

  def perform(date = Date.yesterday)
    DailyResultStatisticsService.new(date).call
  end
end
