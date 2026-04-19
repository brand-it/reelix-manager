# frozen_string_literal: true

# Cleanup old error entries to prevent database bloat
class CleanupOldErrorsJob < ApplicationJob
  queue_as :default

  # Number of days after which errors are deleted
  DAYS_TO_KEEP = 30
  #: Integer

  def perform
    cutoff_date = DAYS_TO_KEEP.days.ago
    deleted_count = ErrorEntry.where('created_at < ?', cutoff_date).delete_all

    Rails.logger.info "[CleanupOldErrorsJob] Deleted #{deleted_count} error entries older than #{DAYS_TO_KEEP} days"
  end
end
