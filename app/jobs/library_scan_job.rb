# frozen_string_literal: true

# Runs the library scanner and then enqueues a TmdbMatcherJob for every
# VideoBlob that is still missing a TMDB ID.
class LibraryScanJob < ApplicationJob
  queue_as :default

  #: () -> void
  def perform
    stats = LibraryScannerService.call
    Rails.logger.info("[LibraryScanJob] Scanner stats: #{stats.inspect}")

    enqueue_tmdb_matchers
  end

  private

  #: () -> void
  def enqueue_tmdb_matchers
    VideoBlob.without_tmdb_id.find_each do |blob|
      TmdbMatcherJob.perform_later(blob.id)
    end
  end
end
