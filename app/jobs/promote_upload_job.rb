# frozen_string_literal: true

# Promotes a completed tus upload to its final destination asynchronously.
# Handles file movement, VideoBlob creation, and TMDB metadata syncing.
class PromoteUploadJob < ApplicationJob
  queue_as :default

  retry_on TheMovieDb::Error, wait: :polynomially_longer, attempts: 3

  #: (
  #    upload_id: String,
  #    tmdb_id: Integer,
  #    filename: String?,
  #    media_type: String,
  #    season_number: Integer?,
  #    episode_number: Integer?
  #  ) -> void
  def perform(upload_id:, tmdb_id:, filename:, media_type:, season_number:, episode_number:)
    # Find tus session
    tus_session = TusUploadSession.find_by(id: upload_id)
    return unless tus_session

    # Check if already finalized
    return if tus_session.finalized?

    upload = Uploads::TusUploadService.call(upload_id:, filename:)

    config = Config::Video.newest
    raise 'No video configuration found' unless config.persisted?

    blob = VideoBlob.new(
      tmdb_id:,
      media_type:,
      season_number:,
      episode_number:,
      path_extension: upload[:extension],
      finalizing: true
    )

    Uploads::TmdbMetadataService.call(video_blob: blob)
    raise "Could not fetch title from TMDB (id: #{tmdb_id})" unless blob.title.present?

    generated_filename = blob.generated_filename
    media_path = blob.media_path
    raise 'Could not build media path' unless generated_filename.present? && media_path.present?

    blob.filename = generated_filename
    blob.key = media_path

    Uploads::PromoteFileService.call(
      upload_id:,
      info: upload[:info],
      extension: upload[:extension],
      video_blob: blob
    )

    blob = VideoBlobs::UpsertFromUploadService.call(
      video_blob: blob
    )

    # Mark session as finalized with video_blob reference
    tus_session.update!(
      finalized: true,
      video_blob_id: blob.id
    )

    # Clear finalizing state
    blob.update(finalizing: false)

    # Queue TMDB sync job
    VideoBlobTmdbSyncJob.perform_later(blob.id)
  rescue Uploads::TusUploadService::Error, TheMovieDb::Error, ActiveRecord::RecordInvalid, SystemCallError
    # Clear finalizing state on error if blob was created
    blob&.update(finalizing: false) if defined?(blob) && blob.respond_to?(:update)
    raise
  end
end
