# frozen_string_literal: true

module Types
  class SeasonType < Types::BaseObject
    description "Full season details from TMDB /tv/{tv_id}/season/{season_number}"

    field :id, Integer, null: false
    field :name, String, null: false
    field :overview, String, null: false
    field :air_date, String, null: true
    field :season_number, Integer, null: false
    field :poster_path, String, null: true
    field :vote_average, Float, null: false
    field :episodes, [ Types::SeasonEpisodeType ], null: false

    #: () -> Integer
    def id            = object["id"]

    #: () -> String
    def name          = object["name"] || ""

    #: () -> String
    def overview      = object["overview"] || ""

    #: () -> Integer
    def season_number = object["season_number"] || 0

    #: () -> Float
    def vote_average  = object["vote_average"] || 0.0

    #: () -> ::Array[::Hash[String, untyped]]
    def episodes      = object["episodes"] || []
  end
end
