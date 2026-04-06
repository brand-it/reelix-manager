# frozen_string_literal: true

class GraphqlController < ApplicationController
  # Doorkeeper token requests are stateless — CSRF doesn't apply.
  # Covers all configured access_token_methods (Authorization header, access_token
  # param, bearer_token param). Session-based requests (GraphiQL in the browser)
  # still use the real session and CSRF protection.
  protect_from_forgery with: :exception
  skip_before_action :verify_authenticity_token, if: :doorkeeper_token_request?

  # Override the standard web-session auth: accept a Doorkeeper Bearer token,
  # or fall back to the Devise session (used by GraphiQL in the browser).
  skip_before_action :authenticate_or_setup!
  before_action :authenticate_graphql_user!

  #: () -> void
  def execute
    variables = prepare_variables(params[:variables])
    query = params[:query]
    operation_name = params[:operationName]
    context = {
      current_user: @current_user,
      doorkeeper_token: @doorkeeper_token
    }
    result = ReelixManagerSchema.execute(query, variables: variables, context: context, operation_name: operation_name)
    render json: result
  rescue StandardError => e
    raise e unless Rails.env.development?
    handle_error_in_development(e)
  end

  private

  # Authenticate via Doorkeeper token (any configured method), or fall back to the
  # Devise session (so GraphiQL works in the browser when logged in).
  # Scope enforcement is handled per-operation inside GraphQL resolvers and mutations.
  #: () -> void
  def authenticate_graphql_user!
    token = doorkeeper_access_token

    if token&.accessible?
      @current_user = User.find_by(id: token.resource_owner_id) #: User?
      @doorkeeper_token = token #: untyped
      return if @current_user
    end

    # Fall back to Devise session (e.g. GraphiQL in the browser).
    if current_user
      @current_user = current_user #: User?
      return
    end

    render json: { errors: [ { message: "Unauthorized" } ] }, status: :unauthorized
  end

  # Handle variables in form data, JSON body, or a blank value
  #: (untyped variables_param) -> ::Hash[String, untyped]
  def prepare_variables(variables_param)
    case variables_param
    when String
      if variables_param.present?
        JSON.parse(variables_param) || {}
      else
        {}
      end
    when Hash
      variables_param
    when ActionController::Parameters
      variables_param.to_unsafe_hash # GraphQL-Ruby will validate name and type of incoming variables.
    when nil
      {}
    else
      raise ArgumentError, "Unexpected parameter: #{variables_param}"
    end
  end

  #: (StandardError e) -> void
  def handle_error_in_development(e)
    logger.error e.message
    logger.error e.backtrace&.join("\n")

    data = {} #: ::Hash[Symbol, untyped]
    render json: { errors: [ { message: e.message, backtrace: e.backtrace } ], data: data }, status: 500
  end

  # Returns a valid Doorkeeper token if one is present via any configured
  # access_token_method (Authorization header, access_token param, bearer_token
  # param). Memoized so the token is only looked up once per request.
  #: () -> untyped
  def doorkeeper_access_token
    @doorkeeper_access_token ||= Doorkeeper::OAuth::Token.authenticate(
      request, *Doorkeeper.configuration.access_token_methods
    ) #: untyped
  end

  # Skip CSRF for any request carrying a valid Doorkeeper access token —
  # covers all configured access_token_methods, not just the Bearer header.
  #: () -> bool
  def doorkeeper_token_request?
    doorkeeper_access_token&.accessible?
  end
end
