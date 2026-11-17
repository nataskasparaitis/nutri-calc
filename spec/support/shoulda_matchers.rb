# One-line matchers such as `it { is_expected.to validate_presence_of(:name) }`.
Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :rspec
    with.library :rails
  end
end
