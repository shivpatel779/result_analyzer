# Monthly averages job. Registered to run *every* day; the trigger-date guard
# lives here so the job only does work on the Monday of the week containing the
# month's third Wednesday. Thin wrapper around Monthly::CalculateAverages.
class MonthlyAveragesJob < ApplicationJob
  queue_as :default

  def perform(date: Date.current)
    return unless Monthly::TriggerDate.run_today?(date)

    Monthly::CalculateAverages.call(date: date)
  end
end
