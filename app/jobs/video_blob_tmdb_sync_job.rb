# frozen_string_literal: true

class VideoBlobTmdbSyncJob < ApplicationJob
  queue_as :default

  retry_on TheMovieDb::Error, wait: :polynomially_longer, attempts: 3

  #: (Integer video_blob_id) -> void
  def perform(video_blob_id)
    blob = VideoBlob.find_by(id: video_blob_id)
    return unless blob
    return unless blob.tmdb_id.present?

    VideoBlobs::TmdbSyncService.call(blob)
  end
end
