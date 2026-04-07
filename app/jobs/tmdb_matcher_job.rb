# frozen_string_literal: true

# Resolves the TMDB ID for a single VideoBlob by searching TMDB by title and year.
# Enqueued by LibraryScanJob for every blob that is missing a tmdb_id.
class TmdbMatcherJob < ApplicationJob
  queue_as :default

  retry_on TheMovieDb::Error, wait: :polynomially_longer, attempts: 3

  #: (Integer video_blob_id) -> void
  def perform(video_blob_id)
    blob = VideoBlob.find_by(id: video_blob_id)
    return unless blob
    return if blob.tmdb_id.present?

    tmdb_id = blob.movie? ? match_movie(blob) : match_tv(blob)
    blob.update!(tmdb_id: tmdb_id) if tmdb_id
  end

  private

  #: (VideoBlob blob) -> Integer?
  def match_movie(blob)
    return nil if blob.title.blank?

    response = TheMovieDb::Search::Movie.new(
      query: blob.title.to_s,
      year:  blob.year
    ).results

    best_match(response["results"] || [], blob.year, "release_date")
  end

  #: (VideoBlob blob) -> Integer?
  def match_tv(blob)
    return nil if blob.title.blank?

    response = TheMovieDb::Search::Tv.new(
      query: blob.title.to_s
    ).results

    best_match(response["results"] || [], blob.year, "first_air_date")
  end

  # Returns the TMDB id of the best-matching result.
  # Prefers an exact year match; falls back to the first result.
  #: (::Array[::Hash[String, untyped]] results, Integer? year, String date_key) -> Integer?
  def best_match(results, year, date_key)
    return nil if results.empty?

    if year
      year_match = results.find do |r|
        r[date_key].to_s[0, 4].to_i == year
      end
      return year_match["id"] if year_match
    end

    results.first["id"]
  end
end
