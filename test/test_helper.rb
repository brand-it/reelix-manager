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

    # Counts the number of real SQL SELECT queries executed inside the block.
    # Filters out SCHEMA introspection, cached queries, and transaction statements
    # (BEGIN/COMMIT/ROLLBACK) to avoid flaky counts that depend on schema-cache warmup.
    def count_sql_queries(&block)
      count   = 0
      counter = ->(_name, _start, _finish, _id, payload) {
        next if payload[:name].in?(%w[ SCHEMA CACHE ])
        next if payload[:cached]
        next if payload[:sql].match?(/\A\s*(BEGIN|COMMIT|ROLLBACK|SAVEPOINT|RELEASE)/i)
        count += 1
      }
      ActiveSupport::Notifications.subscribed(counter, "sql.active_record", &block)
      count
    end
  end
end

module ActionDispatch
  class IntegrationTest
    include Devise::Test::IntegrationHelpers
  end
end
