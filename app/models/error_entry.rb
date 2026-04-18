# frozen_string_literal: true

class ErrorEntry < ApplicationRecord
  # Use 'unacknowledged' instead of 'new' to avoid conflict with ActiveRecord.new
  enum :status, { unacknowledged: 0, acknowledged: 1, resolved: 2 }

  # Sanitize params using Rails' built-in ParameterFilter
  #: (untyped) -> untyped
  def self.sanitize_params(params)
    return {} unless params

    filter = ActiveSupport::ParameterFilter.new(Rails.configuration.filter_parameters)
    # ParameterFilter handles nested hashes but not arrays, so we handle arrays manually
    if params.is_a?(Hash)
      filter.filter(params).with_indifferent_access.to_h.with_indifferent_access
    elsif params.is_a?(Array)
      params.map { |v| v.is_a?(Hash) ? filter.filter(v).with_indifferent_access.to_h.with_indifferent_access : v }
    else
      {}
    end
  end

  # Unified error logging method - delegates to ErrorLoggerService
  #: (StandardError, ?untyped) -> ErrorEntry
  def self.log_error(error, context = nil)
    ErrorLoggerService.call(error, context)
  end
  # Scopes for filtering
  # Note: unacknowledged scope is provided by the enum definition
  scope :recent_first, -> { order(created_at: :desc) }
  scope :by_error_class, ->(error_class) { where(error_class: error_class) }
  scope :by_status, ->(status) { where(status: status) }
  scope :by_fingerprint, ->(fingerprint) { where(fingerprint: fingerprint) }

  # Get latest error from each fingerprint group
  scope :distinct_on_fingerprint, lambda {
    # For PostgreSQL: SELECT DISTINCT ON (fingerprint) ... ORDER BY fingerprint, created_at DESC
    # For SQLite/MySQL: use subquery to get max(id) per fingerprint
    if ActiveRecord::Base.connection.adapter_name == 'PostgreSQL'
      select('DISTINCT ON (fingerprint) *').order(:fingerprint, created_at: :desc)
    else
      # Fallback for SQLite/MySQL: get latest id per fingerprint using Arel
      arel_table = self.arel_table
      subquery = self.select(arel_table[:id].maximum).group('fingerprint')
      where(id: subquery)
    end
  }

  # Get unique error classes for filter dropdown
  #: -> ErrorEntry::ActiveRecord_Relation
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
    return {} unless request_params.present?

    JSON.parse(request_params.to_s)
  rescue JSON::ParserError
    {}
  end

  # Parse JSON job arguments back to hash
  #: -> Hash[untyped, untyped]
  def job_arguments_hash
    return {} unless job_arguments.present?

    JSON.parse(job_arguments.to_s)
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
