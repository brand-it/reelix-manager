# frozen_string_literal: true

module Types
  class SearchResultType < Types::BaseObject
    description 'A single result from a combined movie and TV show search'

    field :id, Integer, null: false
    field :media_type, String, null: false, description: "Either 'movie' or 'tv'"

    # Title fields — movies use 'title', TV shows use 'name'
    field :title, String, null: true
    field :name, String, null: true
    field :original_title, String, null: true
    field :original_name, String, null: true

    # Date fields — movies use 'release_date', TV shows use 'first_air_date'
    field :release_date, String, null: true
    field :first_air_date, String, null: true

    field :overview, String, null: false
    field :poster_path, String, null: true
    field :backdrop_path, String, null: true
    field :profile_path, String, null: true

    field :popularity, Float, null: true
    field :vote_average, Float, null: false
    field :vote_count, Integer, null: false

    field :original_language, String, null: false
    field :genre_ids, [Integer], null: false
    field :adult, Boolean, null: false
    field :video, Boolean, null: false

    # Computed convenience field
    field :display_title, String, null: false,
                                  description: "Best available title: uses 'title' for movies, 'name' for TV shows"

    field :video_blobs, [Types::VideoBlobType], null: false,
                                                description: 'Local video files matched to this result'

    # Provide defaults for fields that TMDB omits on TV show results
    #: () -> bool
    def video           = object['video'] || false

    #: () -> bool
    def adult           = object['adult'] || false

    #: () -> String
    def overview        = object['overview'] || ''

    #: () -> Float
    def vote_average    = object['vote_average'] || 0.0

    #: () -> Integer
    def vote_count      = object['vote_count'] || 0

    #: () -> String
    def original_language = object['original_language'] || ''

    #: () -> ::Array[Integer]
    def genre_ids = object['genre_ids'] || []

    #: () -> String
    def display_title
      object['title'] || object['name'] || 'Unknown'
    end

    #: () -> ::Array[::VideoBlob]
    def video_blobs = dataloader.with(Sources::VideoBlobs).load([object['media_type'], object['id']])
  end
end
