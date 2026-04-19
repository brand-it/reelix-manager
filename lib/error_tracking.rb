# frozen_string_literal: true

module ErrorTracking
  class Middleware
    # Skip error tracking for these paths (assets, health checks, etc.)
    SKIPPED_PATHS = %w[/rails/health /rails/assets /assets].freeze

    def initialize(app)
      @app = app
    end

    def call(env)
      @request = Rack::Request.new(env)

      # Skip certain paths
      return @app.call(env) if should_skip?

      # Let errors propagate to Rails' error handling
      @app.call(env)
    end

    private

    def should_skip?
      SKIPPED_PATHS.any? { |path| @request.path.start_with?(path) }
    end
  end
end
