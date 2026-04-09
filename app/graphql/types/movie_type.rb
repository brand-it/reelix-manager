# frozen_string_literal: true

module Types
  class MovieType < Types::BaseObject
    description "Full movie details from TMDB /movie/{id}"

    field :id, Integer, null: false
    field :title, String, null: false
    field :original_title, String, null: false
    field :overview, String, null: false
    field :tagline, String, null: true
    field :status, String, null: true
    field :homepage, String, null: true
    field :imdb_id, String, null: true

    field :release_date, String, null: true
    field :adult, Boolean, null: false
    field :video, Boolean, null: false

    field :poster_path, String, null: true
    field :backdrop_path, String, null: true

    field :popularity, Float, null: false
    field :vote_average, Float, null: false
    field :vote_count, Integer, null: false

    field :runtime, Integer, null: true,
      description: "Runtime in minutes"
    field :budget, Integer, null: true,
      description: "Production budget in USD"
    field :revenue, Integer, null: true,
      description: "Box office revenue in USD"

    field :original_language, String, null: false
    field :origin_country, [ String ], null: false

    field :genres, [ Types::GenreType ], null: false

    field :video_blobs, [ Types::VideoBlobType ], null: false,
      description: "Local video files matched to this movie"

    #: () -> Integer
    def id               = object["id"]

    #: () -> String
    def title            = object["title"] || ""

    #: () -> String
    def original_title   = object["original_title"] || ""

    #: () -> String
    def overview         = object["overview"] || ""

    #: () -> bool
    def adult            = object["adult"] || false

    #: () -> bool
    def video            = object["video"] || false

    #: () -> Float
    def popularity       = object["popularity"] || 0.0

    #: () -> Float
    def vote_average     = object["vote_average"] || 0.0

    #: () -> Integer
    def vote_count       = object["vote_count"] || 0

    #: () -> String
    def original_language = object["original_language"] || ""

    #: () -> ::Array[String]
    def origin_country   = object["origin_country"] || []

    #: () -> ::Array[::Hash[String, untyped]]
    def genres           = object["genres"] || []

    #: () -> ::Array[::VideoBlob]
    def video_blobs = dataloader.with(Sources::VideoBlobs).load(["movie", object["id"]])
  end
end
