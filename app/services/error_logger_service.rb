# frozen_string_literal: true

# @rbs class ErrorLoggerService < ApplicationService
class ErrorLoggerService < ApplicationService
  # @rbs @error: StandardError
  # @rbs @context: untyped?

  class << self
    #: (StandardError, ?untyped?) -> ErrorEntry
    def call(error, context = nil)
      new(error, context).call
    end
  end

  #: (StandardError, ?untyped?) -> void
  def initialize(error, context = nil)
    super()
    @error = error
    @context = context
  end

  #: () -> ErrorEntry
  def call
    fingerprint = generate_fingerprint(@error.class.name, @error.backtrace&.join("\n"))
    user_info = extract_user_info(@context)

    attributes = build_base_attributes(@error, fingerprint, user_info)
    add_context_attributes(attributes, @context)

    ErrorEntry.create!(**attributes)
  rescue StandardError => e
    Rails.logger.error("ErrorLoggerService: Failed to store error: #{e.message}")
    Rails.logger.error(e.backtrace&.join("\n"))
  end

  private

  #: (untyped?) -> { id: Integer?, email: String? }
  def extract_user_info(context)
    user = nil
    user = context.current_user if context.respond_to?(:current_user)
    user = context[:current_user] if context.respond_to?(:[]) && context[:current_user]

    {
      id: user&.id,
      email: user&.email
    }
  end

  #: (StandardError, String, { id: Integer?, email: String? }) -> untyped
  def build_base_attributes(error, fingerprint, user_info)
    {
      error_class: error.class.name,
      error_message: error.message,
      backtrace: error.backtrace&.join("\n") || 'No backtrace',
      fingerprint: fingerprint,
      status: :unacknowledged,
      user_id: user_info[:id],
      user_email: user_info[:email],
      environment: Rails.env
    }
  end

  #: (untyped, untyped?) -> void
  def add_context_attributes(attributes, context)
    if controller_context?(context)
      add_controller_context(attributes, context)
    elsif job_context?(context)
      add_job_context(attributes, context)
    elsif graphql_context?(context)
      add_graphql_context(attributes, context)
    end
  end

  #: (untyped?) -> bool
  def controller_context?(context)
    context.respond_to?(:request) && context.respond_to?(:params)
  end

  #: (untyped?) -> bool
  def job_context?(context)
    context.is_a?(ActiveJob::Base)
  end

  #: (untyped?) -> bool
  def graphql_context?(context)
    context.is_a?(GraphQL::Query::Context)
  end

  #: (untyped, untyped) -> void
  def add_controller_context(attributes, context)
    attributes[:request_url] = context.request.url
    attributes[:request_method] = context.request.method
    attributes[:request_path] = context.request.path
    attributes[:request_params] = ErrorEntry.sanitize_params(context.params).to_json
  end

  #: (untyped, ActiveJob::Base) -> void
  def add_job_context(attributes, context)
    attributes[:job_class] = context.class.name
    attributes[:job_id] = context.job_id
    attributes[:job_queue] = context.queue_name
    attributes[:job_arguments] = ErrorEntry.sanitize_params(context.arguments).to_json
  end

  #: (untyped, GraphQL::Query::Context) -> void
  def add_graphql_context(attributes, context)
    attributes[:request_path] = '/graphql'
    query_obj = context.query
    query_string = query_obj&.query_string || 'Unknown'
    variables = query_obj&.provided_variables || {}
    attributes[:request_params] = {
      query: query_string[0..500],
      variables: ErrorEntry.sanitize_params(variables)
    }.to_json
  end

  #: (String, String?) -> String
  def generate_fingerprint(error_class, backtrace)
    fingerprint_data = [error_class, backtrace&.lines&.first]
    Digest::SHA256.hexdigest(fingerprint_data.join('|'))[0..15] || 'unknown'
  end
end
