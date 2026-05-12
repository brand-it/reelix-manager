# rbs_inline: disabled
# frozen_string_literal: true

class CleanupExpiredTusUploadsJob < ApplicationJob
  queue_as :default

  # Clean uploads expired longer than tus expiration time + buffer
  EXPIRATION_BUFFER = 1.hour

  #: () -> void
  def perform
    # tus_expiration is in seconds (Float from configuration)
    # EXPIRATION_BUFFER is ActiveSupport::Duration
    total_seconds = Tus::Server.opts[:expiration_time].to_i + EXPIRATION_BUFFER.to_i
    cutoff_time = Time.current - total_seconds

    # Find expired, non-finalized sessions
    expired = TusUploadSession
              .where(finalized: false)
              .where('updated_at < ?', cutoff_time)
              .to_a

    deleted_count = 0
    expired.each do |session|
      # Check if tus file still exists
      tus_path = Tus::Server.opts[:storage].directory.join(session.id)
      info_path = Tus::Server.opts[:storage].directory.join("#{session.id}.info")

      if tus_path.exist? || info_path.exist?
        # Files exist but session is stale — delete tus files
        FileUtils.rm_f(tus_path) if tus_path.exist?
        FileUtils.rm_f(info_path) if info_path.exist?
      end

      # Delete session record
      session.destroy
      deleted_count += 1
    end

    Rails.logger.info "[CleanupExpiredTusUploadsJob] Deleted #{deleted_count} expired sessions"
  end
end
