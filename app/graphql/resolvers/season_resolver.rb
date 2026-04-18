# frozen_string_literal: true

module Resolvers
  # Resolves full season details from TMDB GET /tv/{tv_id}/season/{season_number}.
  class SeasonResolver < Resolvers::BaseResolver
    type Types::SeasonType, null: false

    argument :tv_id, Integer, required: true, description: 'TMDB TV show ID'
    argument :season_number, Integer, required: true, description: 'Season number (1-based)'
    argument :language, String, required: false, default_value: 'en-US',
                                description: 'BCP 47 language tag for translated fields (default en-US)'

    #: (tv_id: Integer, season_number: Integer, language: String) -> ::Hash[String, untyped]
    def resolve(tv_id:, season_number:, language:)
      require_search!
      TheMovieDb::Season.new(tv_id:, season_number:, language:).results(use_cache: true)
    rescue TheMovieDb::InvalidConfig => e
      Rails.logger.error("[TMDB InvalidConfig] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, 'TMDB authentication error. Please contact support.'
    rescue TheMovieDb::Error => e
      Rails.logger.error("[TMDB Error] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, 'TMDB service error. Please try again later.'
    end
  end
end
