# frozen_string_literal: true

module Resolvers
  # Returns VideoBlob records from the local library cache.
  # Optionally filter by media type and/or TMDB ID.
  class VideoBlobsResolver < Resolvers::BaseResolver
    type [Types::VideoBlobType], null: false

    argument :media_type, String,  required: false,
                                   description: "Filter by media type: 'movie' or 'tv'"
    argument :tmdb_id,    Integer, required: false,
                                   description: 'Filter by TMDB ID'

    #: (?media_type: String?, ?tmdb_id: Integer?) -> ::ActiveRecord::Relation
    def resolve(media_type: nil, tmdb_id: nil)
      require_search!

      scope = VideoBlob.all
      scope = scope.where(media_type: media_type) if media_type.present?
      scope = scope.where(tmdb_id:)               if tmdb_id.present?
      scope.order(:title, :season_number, :episode_number)
    rescue ArgumentError => e
      raise GraphQL::ExecutionError, "Invalid argument: #{e.message}"
    end
  end
end
