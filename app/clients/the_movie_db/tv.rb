# frozen_string_literal: true

module TheMovieDb
  # Fetches full TV show details from TMDB GET /tv/{id}.
  #
  # Usage:
  #   TheMovieDb::Tv.new(id: 1396).results
  #   => { "id" => 1396, "name" => "Breaking Bad", ... }
  class Tv < Base
    # @rbs @id: Integer

    #: (id: Integer, ?api_key: String?, ?language: String?) -> void
    def initialize(id:, api_key: nil, language: nil)
      super(api_key: api_key, language: language)
      @id = id #: Integer
    end

    private

    #: () -> String
    def path
      "tv/#{@id}"
    end
  end
end
