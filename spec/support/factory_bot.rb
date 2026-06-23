RSpec.configure do |config|
  # Use `build`, `create`, etc. directly in specs without the `FactoryBot.` prefix.
  config.include FactoryBot::Syntax::Methods
end
