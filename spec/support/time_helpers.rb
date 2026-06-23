RSpec.configure do |config|
  # Make `travel_to`, `freeze_time`, etc. available for deterministic, date-sensitive specs
  # (EOD aggregation, the third-Wednesday trigger, monthly lookback).
  config.include ActiveSupport::Testing::TimeHelpers
end
