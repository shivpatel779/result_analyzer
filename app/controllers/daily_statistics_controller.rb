class DailyStatisticsController < ApplicationController
  def index
    # Most recent days first, then subject alphabetically; grouped by date in the view.
    @statistics_by_date = DailyResultStatistic
      .order(date: :desc, subject: :asc)
      .group_by(&:date)
  end
end
