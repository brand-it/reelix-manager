# frozen_string_literal: true

# Resolves the TMDB ID and poster URL for a single VideoBlob by searching TMDB
# by title and year, then persists the result.
#
# Usage:
#   TmdbMatcherService.call(blob)
class TmdbMatcherService < ApplicationService
  class << self
    #: (VideoBlob blob) -> void
    def call(...) = super
  end

  # @rbs @blob: VideoBlob

  #: (VideoBlob blob) -> void
  def initialize(blob)
    @blob = blob #: VideoBlob
  end

  #: () -> void
  def call
    return if @blob.title.blank?

    match = @blob.movie? ? match_movie : match_tv
    return unless match

    @blob.update!(
      tmdb_id:    match[:id],
      poster_url: match[:poster_path].present? ? poster_url(match[:poster_path]) : nil
    )
  end

  private

  #: () -> { id: Integer, poster_path: String }?
  def match_movie
    response = TheMovieDb::Search::Movie.new(
      query: @blob.title.to_s,
      year:  @blob.year
    ).results

    best_match(response["results"] || [], @blob.year, "release_date")
  end

  #: () -> { id: Integer, poster_path: String }?
  def match_tv
    response = TheMovieDb::Search::Tv.new(
      query: @blob.title.to_s
    ).results

    best_match(response["results"] || [], @blob.year, "first_air_date")
  end

  # Returns the best-matching TMDB result as { id:, poster_path: }.
  # Prefers an exact year match; falls back to the first result.
  #: (::Array[::Hash[String, String | Integer | nil]] results, Integer? year, String date_key) -> { id: Integer, poster_path: String }?
  def best_match(results, year, date_key)
    return if results.empty?

    result = if year
      results.find { |r| r[date_key].to_s[0, 4].to_i == year } || results.first
    else
      results.first
    end

    return unless result

    id = result["id"].to_i           #: Integer
    poster_path = result["poster_path"].to_s #: String
    { id: id, poster_path: poster_path }
  end

  TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p"

  #: (String poster_path, ?size: String) -> String
  def poster_url(poster_path, size: "w342")
    "#{TMDB_IMAGE_BASE_URL}/#{size}#{poster_path}"
  end
end
