# frozen_string_literal: true

module TheMovieDb
  # Fetches full movie details from TMDB GET /movie/{id}.
  #
  # Usage:
  #   TheMovieDb::Movie.new(id: 27205).results
  #   => { "id" => 27205, "title" => "Inception", ... }
  class Movie < Base
    # @rbs @id: Integer

    #: (id: Integer, ?api_key: String?, ?language: String?) -> void
    def initialize(id:, api_key: nil, language: nil)
      super(api_key: api_key, language: language)
      @id = id #: Integer
    end

    private

    #: () -> String
    def path
      "movie/#{@id}"
    end
  end
end
