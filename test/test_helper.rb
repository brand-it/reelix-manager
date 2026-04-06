ENV["RAILS_ENV"] ||= "test"
require_relative "../config/environment"
require "rails/test_help"

Shoulda::Matchers.configure do |config|
  config.integrate do |with|
    with.test_framework :minitest
    with.library :rails
  end
end

module ActiveSupport
  class TestCase
    # Run tests in parallel with specified workers
    parallelize(workers: :number_of_processors)

    # Load all fixtures so existing fixture-based tests continue to work
    fixtures :all

    include FactoryBot::Syntax::Methods

    # Stub TheMovieDb::Base.ping so model validations don't make real network
    # calls in tests. Any key is treated as valid; test a real key separately.
    setup do
      TheMovieDb::Base.define_singleton_method(:ping) { |**| true }
    end

    teardown do
      TheMovieDb::Base.singleton_class.remove_method(:ping)
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
