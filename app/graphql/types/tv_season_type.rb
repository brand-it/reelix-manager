# frozen_string_literal: true

module Types
  # Summary season object returned inside a TvType response.
  # For full episode details use the SeasonType resolver.
  class TvSeasonType < Types::BaseObject
    description 'Summary of a TV season as returned inside a TV show detail response'

    field :id, Integer, null: false
    field :name, String, null: false
    field :overview, String, null: false
    field :air_date, String, null: true
    field :episode_count, Integer, null: false
    field :season_number, Integer, null: false
    field :poster_path, String, null: true
    field :vote_average, Float, null: false

    #: () -> Integer
    def id             = object['id']

    #: () -> String
    def name           = object['name'] || ''

    #: () -> String
    def overview       = object['overview'] || ''

    #: () -> Integer
    def episode_count  = object['episode_count'] || 0

    #: () -> Integer
    def season_number  = object['season_number'] || 0

    #: () -> Float
    def vote_average   = object['vote_average'] || 0.0
  end
end
