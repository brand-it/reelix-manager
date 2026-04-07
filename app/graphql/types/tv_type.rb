# frozen_string_literal: true

module Types
  class TvType < Types::BaseObject
    description "Full TV show details from TMDB /tv/{id}"

    field :id, Integer, null: false
    field :name, String, null: false
    field :original_name, String, null: false
    field :overview, String, null: false
    field :tagline, String, null: true
    field :status, String, null: true
    field :homepage, String, null: true

    field :show_type, String, null: true,
      description: "TMDB show type (e.g. Scripted, Reality, Documentary)"

    field :first_air_date, String, null: true
    field :last_air_date, String, null: true
    field :in_production, Boolean, null: false
    field :adult, Boolean, null: false

    field :poster_path, String, null: true
    field :backdrop_path, String, null: true

    field :popularity, Float, null: false
    field :vote_average, Float, null: false
    field :vote_count, Integer, null: false

    field :number_of_seasons, Integer, null: false
    field :number_of_episodes, Integer, null: false
    field :episode_run_time, [ Integer ], null: false,
      description: "Typical episode runtimes in minutes"

    field :original_language, String, null: false
    field :languages, [ String ], null: false
    field :origin_country, [ String ], null: false

    field :genres, [ Types::GenreType ], null: false
    field :seasons, [ Types::TvSeasonType ], null: false,
      description: "Season summary list. Use the season query for full episode details."

    #: () -> Integer
    def id                 = object["id"]

    #: () -> String
    def name               = object["name"] || ""

    #: () -> String
    def original_name      = object["original_name"] || ""

    #: () -> String
    def overview           = object["overview"] || ""

    #: () -> String?
    def show_type          = object["type"]

    #: () -> bool
    def in_production      = object["in_production"] || false

    #: () -> bool
    def adult              = object["adult"] || false

    #: () -> Float
    def popularity         = object["popularity"] || 0.0

    #: () -> Float
    def vote_average       = object["vote_average"] || 0.0

    #: () -> Integer
    def vote_count         = object["vote_count"] || 0

    #: () -> Integer
    def number_of_seasons  = object["number_of_seasons"] || 0

    #: () -> Integer
    def number_of_episodes = object["number_of_episodes"] || 0

    #: () -> ::Array[Integer]
    def episode_run_time   = object["episode_run_time"] || []

    #: () -> String
    def original_language  = object["original_language"] || ""

    #: () -> ::Array[String]
    def languages          = object["languages"] || []

    #: () -> ::Array[String]
    def origin_country     = object["origin_country"] || []

    #: () -> ::Array[::Hash[String, untyped]]
    def genres             = object["genres"] || []

    #: () -> ::Array[::Hash[String, untyped]]
    def seasons            = object["seasons"] || []
  end
end
