# frozen_string_literal: true

module Types
  class SeasonEpisodeType < Types::BaseObject
    description "A single episode within a season from TMDB /tv/{id}/season/{season_number}"

    field :id, Integer, null: false
    field :name, String, null: false
    field :overview, String, null: false
    field :air_date, String, null: true
    field :episode_number, Integer, null: false
    field :episode_type, String, null: true
    field :production_code, String, null: true
    field :runtime, Integer, null: true, description: "Episode runtime in minutes"
    field :season_number, Integer, null: false
    field :show_id, Integer, null: false
    field :still_path, String, null: true
    field :vote_average, Float, null: false
    field :vote_count, Integer, null: false

    field :video_blobs, [ Types::VideoBlobType ], null: false,
      description: "Local video files matched to this episode"

    #: () -> Integer
    def id              = object["id"]

    #: () -> String
    def name            = object["name"] || ""

    #: () -> String
    def overview        = object["overview"] || ""

    #: () -> Integer
    def episode_number  = object["episode_number"] || 0

    #: () -> Integer
    def season_number   = object["season_number"] || 0

    #: () -> Integer
    def show_id         = object["show_id"] || 0

    #: () -> Float
    def vote_average    = object["vote_average"] || 0.0

    #: () -> Integer
    def vote_count      = object["vote_count"] || 0

    #: () -> ::ActiveRecord::Relation
    def video_blobs = ::VideoBlob.where(
      media_type: :tv,
      tmdb_id: object["show_id"],
      season_number: object["season_number"],
      episode_number: object["episode_number"]
    )
  end
end
