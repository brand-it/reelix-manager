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

      begin
        @app.call(env)
      rescue StandardError => e
        # Store the error
        store_error(e, env)

        # Re-raise so Rails can still show error page
        raise
      end
    end

    private

    def should_skip?
      SKIPPED_PATHS.any? { |path| @request.path.start_with?(path) }
    end

    def store_error(error, env)
      # Build a pseudo-controller object for log_error
      controller_proxy = Object.new
      controller_proxy.define_singleton_method(:request) { @request }
      controller_proxy.define_singleton_method(:params) { @request.params }
      controller_proxy.define_singleton_method(:current_user) do
        user_id = nil
        user_email = nil
        if env["rack.session"] && env["rack.session"][:user_id]
          user_id = env["rack.session"][:user_id]
          user_email = env["rack.session"][:user_email]
        end
        # Return a simple user object if we have user info
        if user_id
          user = Object.new
          user.define_singleton_method(:id) { user_id }
          user.define_singleton_method(:email) { user_email }
          user
        end
      end

      ErrorEntry.log_error(error, controller_proxy)
    end
  end
end
