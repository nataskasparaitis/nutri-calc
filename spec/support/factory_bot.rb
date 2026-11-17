# Lets specs call `create(:food)` instead of `FactoryBot.create(:food)`.
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
end
