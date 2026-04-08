require "spec_helper"
ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
abort("The Rails environment is running in production mode!") if Rails.env.production?
require "rspec/rails"
require "devise"
Dir[Rails.root.join("spec/support/**/*.rb")].sort.each { |f| require f }

# CI runs `db:test:prepare` before the suite. Skipping this check avoids
# false positives in local Windows environments where migration metadata can desync.

RSpec.configure do |config|
  config.fixture_paths = [
    Rails.root.join("test/fixtures")
  ]

  config.use_transactional_fixtures = true
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include TestDataHelper
  config.before(:each) { ensure_currencies! }
  config.infer_spec_type_from_file_location!
  config.filter_rails_from_backtrace!
end
