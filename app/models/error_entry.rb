# frozen_string_literal: true

class ErrorEntry < ApplicationRecord
  # Use 'unacknowledged' instead of 'new' to avoid conflict with ActiveRecord.new
  enum :status, { unacknowledged: 0, acknowledged: 1, resolved: 2 }

  # Sensitive params to filter out
  SENSITIVE_PARAMS = %w[password password_confirmation current_password new_password].freeze
  #: Array[String]

  # Generate a fingerprint for grouping similar errors
  # Uses error class + first line of backtrace
  # rubocop:disable Steep/UnusedMethodSignature
  def self.generate_fingerprint(error_class, backtrace)
    return "unknown" unless backtrace && !backtrace.blank?

    first_line = backtrace.split("\n").first.to_s
    # Hash the combination to create a short fingerprint
    Digest::SHA256.hexdigest("#{error_class}|#{first_line}")[0..15]
  end

  # Sanitize params by removing sensitive values
  #: (untyped) -> Hash[untyped, untyped]
  def self.sanitize_params(params)
    return {} unless params

    if params.is_a?(Hash)
      params.reject { |k, _| SENSITIVE_PARAMS.include?(k.to_s) }.transform_values do |value|
        if value.is_a?(Hash)
          sanitize_params(value)
        elsif value.is_a?(Array)
          value.map { |v| v.is_a?(Hash) ? sanitize_params(v) : v }
        else
          value
        end
      end
    else
      {}
    end
  end

  # Unified error logging method
  # Pass the error object and optional context (controller, job, or GraphQL context)
  #: (StandardError, ?(ApplicationController | ActiveJob::Base | GraphQL::Query::Context)) -> ErrorEntry
  def self.log_error(error, context = nil)
    begin
      # Generate fingerprint
      fingerprint = generate_fingerprint(error.class.name, error.backtrace&.join("\n"))

      # Extract user context
      user_id = nil
      user_email = nil
      if context.respond_to?(:current_user)
        user = context.current_user
        user_id = user&.id if user.respond_to?(:id)
        user_email = user&.email if user.respond_to?(:email)
      elsif context.respond_to?(:[]) && context[:current_user]  # GraphQL context
        user = context[:current_user]
        user_id = user&.id if user.respond_to?(:id)
        user_email = user&.email if user.respond_to?(:email)
      end

      # Build attributes based on context type
      attributes = {
        error_class: error.class.name,
        error_message: error.message,
        backtrace: error.backtrace&.join("\n") || "No backtrace",
        fingerprint: fingerprint,
        status: :unacknowledged,
        user_id: user_id,
        user_email: user_email,
        environment: Rails.env
      }

      # Add request context if from controller
      if context.respond_to?(:request) && context.respond_to?(:params)  # Controller
        attributes[:request_url] = context.request.url
        attributes[:request_method] = context.request.method
        attributes[:request_path] = context.request.path
        attributes[:request_params] = sanitize_params(context.params).to_json
      elsif context.is_a?(ActiveJob::Base)  # Job
        attributes[:job_class] = context.class.name
        attributes[:job_id] = context.job_id
        attributes[:job_queue] = context.queue_name
        attributes[:job_arguments] = sanitize_params(context.arguments).to_json
      elsif context.is_a?(GraphQL::Query::Context)  # GraphQL context
        attributes[:request_path] = "/graphql"
        query_obj = context.query
        query_string = query_obj&.query_string || "Unknown"
        variables = query_obj&.provided_variables || {}
        attributes[:request_params] = {
          query: query_string[0..500],
          variables: sanitize_params(variables)
        }.to_json
      end

      create!(attributes)
    rescue => e
      # If we can't store the error, log it but don't raise to avoid infinite loops
      Rails.logger.error("ErrorEntry.log_error: Failed to store error: #{e.message}")
      Rails.logger.error(e.backtrace.join("\n"))
    end
  end



  # Scopes for filtering
  scope :unacknowledged, -> { where.not(status: [ :acknowledged, :resolved ]) }
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_error_class, ->(error_class) { where(error_class: error_class) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_fingerprint, ->(fingerprint) { where(fingerprint: fingerprint) }

  # Get latest error from each fingerprint group
  scope :distinct_on_fingerprint, -> {
    # For PostgreSQL: SELECT DISTINCT ON (fingerprint) ... ORDER BY fingerprint, created_at DESC
    # For SQLite/MySQL: use subquery to get max(id) per fingerprint
    if ActiveRecord::Base.connection.adapter_name == "PostgreSQL"
      select("DISTINCT ON (fingerprint) *").order(:fingerprint, created_at: :desc)
    else
      # Fallback for SQLite/MySQL: get latest id per fingerprint using Arel
      arel_table = self.arel_table
      subquery = self.select(arel_table[:id].maximum).group(arel_table[:fingerprint])
      where(id: subquery)
    end
  }

  # Get unique error classes for filter dropdown
  #: -> Array[ErrorEntry]
  def self.unique_error_classes
    select(:error_class).distinct.order(:error_class)
  end

  # Get count by status
  #: -> Hash[Symbol, Integer]
  def self.counts_by_status
    group(:status).count
  end

  # Parse JSON params back to hash
  #: -> Hash[untyped, untyped]
  def request_params_hash
    return {} unless request_params
    JSON.parse(request_params)
  rescue JSON::ParserError
    {}
  end

  # Parse JSON job arguments back to hash
  #: -> Hash[untyped, untyped]
  def job_arguments_hash
    return {} unless job_arguments
    JSON.parse(job_arguments)
  rescue JSON::ParserError
    {}
  end

  # Check if this error is from a request
  #: -> bool
  def from_request?
    request_path.present?
  end

  # Check if this error is from a job
  #: -> bool
  def from_job?
    job_class.present?
  end
end
