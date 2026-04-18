# frozen_string_literal: true

# Register ErrorTracking middleware
# This middleware wraps all requests and captures any StandardError that is raised
require_dependency Rails.root.join('lib/error_tracking')

Rails.application.config.middleware.use(ErrorTracking::Middleware)
