class MonthlyResultAveragesJob < ApplicationJob
 queue_as :default

  def perform
    MonthlyResultAveragesService.new.call
  end
end
