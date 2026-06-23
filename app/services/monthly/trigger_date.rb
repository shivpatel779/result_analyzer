module Monthly
  # Resolves the day the monthly averaging job is allowed to run: the Monday of
  # the week (Mon–Sun) that contains the third Wednesday of the month.
  #
  # Because Monday precedes Wednesday within the same Mon–Sun week, that Monday is
  # always two days before the third Wednesday — and always lands in the same
  # calendar month as the third Wednesday.
  module TriggerDate
    WEDNESDAY = 3 # Date#wday: Sunday = 0 ... Wednesday = 3

    module_function

    # The trigger Monday for the month containing +date+.
    def trigger_for(date)
      third_wednesday(date) - 2
    end

    # The third Wednesday of the month containing +date+.
    def third_wednesday(date)
      first = date.to_date.beginning_of_month
      offset_to_first_wednesday = (WEDNESDAY - first.wday) % 7
      first_wednesday = first + offset_to_first_wednesday
      first_wednesday + 14
    end

    # Should the monthly job do work today?
    def run_today?(today = Date.current)
      today.to_date == trigger_for(today)
    end
  end
end
