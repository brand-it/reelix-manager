# frozen_string_literal: true

# Resolves the TMDB ID and poster URL for a single VideoBlob by searching TMDB by title and year.
# Enqueued by LibraryScanJob for every blob that is missing a tmdb_id.
class TmdbMatcherJob < ApplicationJob
  queue_as :default

  retry_on TheMovieDb::Error, wait: :polynomially_longer, attempts: 3

  #: (Integer video_blob_id) -> void
  def perform(video_blob_id)
    blob = VideoBlob.find_by(id: video_blob_id)
    return unless blob
    return if blob.tmdb_id.present?

    match = blob.movie? ? match_movie(blob) : match_tv(blob)
    return unless match

    attrs = { #: Hash[Symbol, Integer | String | nil]
      tmdb_id:    match[:id],
      poster_url: match[:poster_path].present? ? VideoBlob.poster_url_for(match[:poster_path]) : nil
    }
    blob.update!(attrs)
  end

  private

  #: (VideoBlob blob) -> { id: Integer, poster_path: String }?
  def match_movie(blob)
    return nil if blob.title.blank?

    response = TheMovieDb::Search::Movie.new(
      query: blob.title.to_s,
      year:  blob.year
    ).results

    best_match(response["results"] || [], blob.year, "release_date")
  end

  #: (VideoBlob blob) -> { id: Integer, poster_path: String }?
  def match_tv(blob)
    return nil if blob.title.blank?

    response = TheMovieDb::Search::Tv.new(
      query: blob.title.to_s
    ).results

    best_match(response["results"] || [], blob.year, "first_air_date")
  end

  # Returns a hash with :id and :poster_path for the best-matching result.
  # Prefers an exact year match; falls back to the first result.
  #: (::Array[::Hash[String, String | Integer | nil]] results, Integer? year, String date_key) -> { id: Integer, poster_path: String }?
  def best_match(results, year, date_key)
    return nil if results.empty?

    result = if year
      results.find { |r| r[date_key].to_s[0, 4].to_i == year } || results.first
    else
      results.first
    end

    return nil unless result

    id = result["id"].to_i           #: Integer
    poster_path = result["poster_path"].to_s #: String
    { id: id, poster_path: poster_path }
  end
end
