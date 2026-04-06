# frozen_string_literal: true

# Mixin for GraphQL resolvers and mutations that enforces Doorkeeper token scopes.
# Include in BaseResolver and BaseMutation so all resolvers/mutations inherit it.
#
# Scope checks are bypassed entirely for session-based requests (e.g. GraphiQL
# in the browser) where a logged-in user has no Doorkeeper token. Token-based
# API clients must present a token with the appropriate scope.
#
# Each scope has a predicate (can_search?) and an enforcer (require_search!).
# The enforcer raises a GraphQL::ExecutionError if the scope is not present.
# All predicates include the 'all' scope as a pass-through.
#
# Adding a new scope:
#   1. Add optional_scope in config/initializers/doorkeeper.rb
#   2. Add it to DOORKEEPER_SCOPES in config/initializers/provision_reelix_application.rb
#   3. Add can_<scope>? and require_<scope>! methods below
#   4. Call require_<scope>! in the relevant resolver/mutation
module ScopeEnforceable
  def can_search?
    return true if session_user?
    token = context[:doorkeeper_token]
    token&.includes_scope?("all") || token&.includes_scope?("search")
  end

  def require_search!
    return if can_search?

    raise GraphQL::ExecutionError.new(
      "Forbidden: search scope required",
      extensions: { code: "FORBIDDEN" }
    )
  end

  def can_upload?
    return true if session_user?
    token = context[:doorkeeper_token]
    token&.includes_scope?("all") || token&.includes_scope?("upload")
  end

  def require_upload!
    return if can_upload?

    raise GraphQL::ExecutionError.new(
      "Forbidden: upload scope required",
      extensions: { code: "FORBIDDEN" }
    )
  end

  private

  # Returns true when the request is authenticated via Devise session rather
  # than a Doorkeeper token (e.g. GraphiQL in the browser).
  def session_user?
    context[:current_user].present? && context[:doorkeeper_token].nil?
  end
end
