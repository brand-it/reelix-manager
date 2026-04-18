# frozen_string_literal: true

module Resolvers
  class BaseResolver < GraphQL::Schema::Resolver
    include ScopeEnforceable

    private

    # Scrubs sensitive values from error messages before logging.
    #: (String? message) -> String
    def sanitize_error_message(message)
      return '' if message.nil?

      message.dup
             .gsub(/api_key=[^&\s]*/i, 'api_key=[REDACTED]')
             .gsub(/(Bearer\s+)[A-Za-z0-9\-._]+/i, '\1[REDACTED]')
    end
  end
end
