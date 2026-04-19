# frozen_string_literal: true

class ApplicationJob < ActiveJob::Base
  # Automatically retry jobs that encountered a deadlock
  # retry_on ActiveRecord::Deadlocked

  # Most jobs are safe to ignore if the underlying records are no longer available
  # discard_on ActiveJob::DeserializationError

  # Override perform_now to capture errors
  #: (*untyped) -> untyped
  def perform_now(*args)
    super
  rescue StandardError => e
    # Store the error
    store_error(e, args)
    # Re-raise so ActiveJob can handle it
    raise
  end

  private

  #: (StandardError, Array[untyped]) -> void
  def store_error(error, _args)
    # Pass self as context - ApplicationJob has job_class, job_id, queue_name, arguments
    ErrorEntry.log_error(error, self)
  end
end
