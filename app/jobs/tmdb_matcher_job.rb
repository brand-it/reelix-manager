# frozen_string_literal: true

# Enqueued by LibraryScanJob for every blob that is missing a tmdb_id.
# Delegates all matching logic to TmdbMatcherService.
class TmdbMatcherJob < ApplicationJob
  queue_as :default

  retry_on TheMovieDb::Error, wait: :polynomially_longer, attempts: 3

  #: (Integer video_blob_id) -> void
  def perform(video_blob_id)
    blob = VideoBlob.find_by(id: video_blob_id)
    return unless blob
    return if blob.tmdb_id.present?

    TmdbMatcherService.call(blob)
  end
end
