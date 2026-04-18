# frozen_string_literal: true

module Types
  class VideoBlobType < Types::BaseObject
    description 'A video file found in the movie or TV library'

    field :id,                  Integer, null: false
    field :key,                 String,  null: false, description: 'Full file path on disk'
    field :filename,            String,  null: false
    field :content_type,        String,  null: true
    field :media_type,          String,  null: false,  description: 'movie or tv'
    field :tmdb_id,             Integer, null: true,   description: 'TMDB ID (nil until matched)'
    field :title,               String,  null: true
    field :year,                Integer, null: true
    field :edition,             String,  null: true
    field :season_number,       Integer, null: true
    field :episode_number,      Integer, null: true
    field :episode_last_number, Integer, null: true
    field :part,                Integer, null: true
    field :extra_type,          String,  null: false
    field :extra_type_number,   Integer, null: true
    field :poster_url,          String,  null: true
    field :plex_version,        Boolean, null: false
    field :optimized,           Boolean, null: false
    field :created_at,          String,  null: false
    field :updated_at,          String,  null: false

    #: () -> Integer
    def id = object.id

    #: () -> String
    def key = object.key

    #: () -> String
    def filename = object.filename

    #: () -> String
    def media_type = object.media_type

    #: () -> String
    def extra_type = object.extra_type

    #: () -> bool
    def plex_version = object.plex_version

    #: () -> bool
    def optimized = object.optimized

    #: () -> String
    def created_at = object.created_at.iso8601

    #: () -> String
    def updated_at = object.updated_at.iso8601
  end
end
