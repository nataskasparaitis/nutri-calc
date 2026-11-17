require "rails_helper"

# Builds every factory and fails if any of them produces an invalid record,
# so broken test data is caught in one place instead of in random specs.
RSpec.describe "FactoryBot factories" do
  it "are all valid" do
    expect { FactoryBot.lint(traits: true) }.not_to raise_error
  end
end
