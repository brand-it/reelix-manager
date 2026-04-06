# frozen_string_literal: true

module Resolvers
  # Resolves full movie details from TMDB GET /movie/{id}.
  class MovieResolver < Resolvers::BaseResolver
    type Types::MovieType, null: false

    argument :id, Integer, required: true, description: "TMDB movie ID"
    argument :language, String, required: false, default_value: "en-US",
      description: "BCP 47 language tag for translated fields (default en-US)"

    #: (id: Integer, language: String) -> ::Hash[String, untyped]
    def resolve(id:, language:)
      require_search!
      TheMovieDb::Movie.new(id:, language:).results(use_cache: true)
    rescue TheMovieDb::InvalidConfig => e
      Rails.logger.error("[TMDB InvalidConfig] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, "TMDB authentication error. Please contact support."
    rescue TheMovieDb::Error => e
      Rails.logger.error("[TMDB Error] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, "TMDB service error. Please try again later."
    end
  end
end
