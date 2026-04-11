# frozen_string_literal: true

module VideoBlobs
  # Refreshes TMDB-backed metadata for a blob when the tmdb_id is already known.
  # This is intended for background enrichment after upload finalization.
  class TmdbSyncService < ApplicationService
    TMDB_IMAGE_BASE_URL = "https://image.tmdb.org/t/p"

    class << self
      #: (VideoBlob blob) -> void
      def call(...) = super
    end

    # @rbs @blob: VideoBlob

    #: (VideoBlob blob) -> void
    def initialize(blob)
      @blob = blob
    end

    #: () -> void
    def call
      return unless blob.tmdb_id.present?

      data = blob.tv? ? TheMovieDb::Tv.new(id: blob.tmdb_id).results : TheMovieDb::Movie.new(id: blob.tmdb_id).results
      title_key = blob.tv? ? "name" : "title"
      date_key = blob.tv? ? "first_air_date" : "release_date"

      blob.update!(
        title: fetched_title(data[title_key]) || blob.title,
        year: fetched_year(data[date_key]) || blob.year,
        poster_url: build_poster_url(data["poster_path"])
      )
    end

    private

    attr_reader :blob

    #: (String?) -> String?
    def fetched_title(raw_title)
      raw_title.to_s.presence
    end

    #: (String?) -> Integer?
    def fetched_year(raw_date)
      extract_year(raw_date)
    end

    #: (String? raw_date) -> Integer?
    def extract_year(raw_date)
      year = raw_date.to_s.slice(0, 4)
      return unless year&.match?(/\A\d{4}\z/)

      year.to_i
    end

    #: (String? poster_path) -> String?
    def build_poster_url(poster_path)
      return unless poster_path.present?

      "#{TMDB_IMAGE_BASE_URL}/w500#{poster_path}"
    end
  end
end
