# rbs_inline: disabled
# frozen_string_literal: true

class CleanupStuckFinalizingBlobsJob < ApplicationJob
  queue_as :default

  # Time threshold for stuck finalizing blobs (2 days)
  STUCK_THRESHOLD = 2.days

  #: () -> void
  def perform
    stuck = VideoBlob
            .where(finalizing: true)
            .where('updated_at < ?', STUCK_THRESHOLD.ago)
            .to_a

    deleted_count = 0
    stuck.each do |blob|
      # Log the stuck blob
      Rails.logger.warn "[CleanupStuckFinalizingBlobsJob] Stuck blob: #{blob.id} (#{blob.filename})"

      # Delete file if it exists
      FileUtils.rm_f(blob.key)

      # Delete the blob
      blob.destroy
      deleted_count += 1
    end

    Rails.logger.info "[CleanupStuckFinalizingBlobsJob] Deleted #{deleted_count} stuck blobs"
  end
end
