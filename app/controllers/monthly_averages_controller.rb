class MonthlyAveragesController < ApplicationController
  def index
    @monthly_averages = MonthlyResultAverage.order(period: :desc, subject: :asc)
  end
end
