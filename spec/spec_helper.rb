# Plain RSpec settings (no Rails). Rails-specific setup lives in rails_helper.rb.
# See https://rubydoc.info/gems/rspec-core/RSpec/Core/Configuration
RSpec.configure do |config|
  config.expect_with :rspec do |expectations|
    expectations.include_chain_clauses_in_custom_matcher_descriptions = true
  end

  config.mock_with :rspec do |mocks|
    # Fails a test if it stubs a method that does not exist on the real object.
    mocks.verify_partial_doubles = true
  end

  config.shared_context_metadata_behavior = :apply_to_host_groups

  # Run only tests tagged with `focus: true` when any exist (handy while developing; never commit it).
  config.filter_run_when_matching :focus

  # Allows `rspec --only-failures` and `rspec --next-failure`.
  config.example_status_persistence_file_path = "spec/examples.txt"

  # Only allow `RSpec.describe`, not the global `describe`.
  config.disable_monkey_patching!

  config.default_formatter = "doc" if config.files_to_run.one?

  # Print the 10 slowest examples after each run.
  config.profile_examples = 10

  # Run tests in random order so hidden dependencies between tests are exposed.
  # Reproduce a failing order with `rspec --seed <number>`.
  config.order = :random
  Kernel.srand config.seed
end
