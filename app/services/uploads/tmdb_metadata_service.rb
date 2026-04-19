# frozen_string_literal: true

module Uploads
  # Fetches the minimum TMDB metadata required to build the final media path.
  # This stays synchronous because the upload path depends on the canonical
  # title/year (and TV episode title when applicable).
  class TmdbMetadataService < ApplicationService
    class << self
      #: (video_blob: VideoBlob) -> VideoBlob
      def call(video_blob:)
        new(video_blob:).call
      end
    end

    # @rbs @video_blob: VideoBlob

    #: (video_blob: VideoBlob) -> void
    def initialize(video_blob:)
      @video_blob = video_blob
    end

    #: () -> VideoBlob
    def call
      @video_blob.tv? ? apply_tv_metadata : apply_movie_metadata
      @video_blob
    end

    private

    #: () -> void
    def apply_movie_metadata
      tmdb_id = @video_blob.tmdb_id
      raise ArgumentError, 'tmdb_id is required' unless tmdb_id

      data = TheMovieDb::Movie.new(id: tmdb_id).results
      @video_blob.title = data['title'].to_s.presence
      @video_blob.year = extract_year(data['release_date'])
      @video_blob.episode_title = nil
    end

    #: () -> void
    def apply_tv_metadata
      tmdb_id = @video_blob.tmdb_id
      raise ArgumentError, 'tmdb_id is required' unless tmdb_id

      data = TheMovieDb::Tv.new(id: tmdb_id).results
      @video_blob.title = data['name'].to_s.presence
      @video_blob.year = extract_year(data['first_air_date'])
      @video_blob.episode_title = fetch_episode_title
    end

    #: () -> String?
    def fetch_episode_title
      tmdb_id = @video_blob.tmdb_id
      season_number = @video_blob.season_number
      episode_number = @video_blob.episode_number
      return unless tmdb_id && season_number && episode_number

      season_data = TheMovieDb::Season.new(tv_id: tmdb_id, season_number: season_number).results
      season_data['episodes']
        &.find { |episode| episode['episode_number'] == episode_number }
        &.dig('name')
        &.to_s
        &.presence
    end

    #: (String? raw_date) -> Integer?
    def extract_year(raw_date)
      year = raw_date.to_s.slice(0, 4)
      return unless year&.match?(/\A\d{4}\z/)

      year.to_i
    end
  end
end
