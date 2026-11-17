# SimpleCov must start before any application code is loaded, otherwise that code is not measured.
# It lives here rather than in spec_helper.rb because Rails generators also load spec_helper.rb (via .rspec).
require "simplecov"

SimpleCov.start "rails" do
  enable_coverage :branch

  # Enforced in CI (GitHub Actions sets CI=true). Locally, open coverage/index.html to see what is untested.
  minimum_coverage line: 100, branch: 100 if ENV["CI"]
end

require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"

# Load shared helpers, matchers and contexts from spec/support/.
Rails.root.glob("spec/support/**/*.rb").sort_by(&:to_s).each { |f| require f }

# Fail fast if migrations are pending: keeps the test schema in sync with db/schema.rb.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end

RSpec.configure do |config|
  # Each example runs inside a database transaction that is rolled back afterwards,
  # so tests never see each other's data.
  config.use_transactional_fixtures = true

  # Infer spec type (model, request, job, ...) from the file location, e.g. spec/models -> type: :model.
  config.infer_spec_type_from_file_location!

  config.filter_rails_from_backtrace!
end
