# frozen_string_literal: true

module TheMovieDb
  # Fetches full season details from TMDB GET /tv/{tv_id}/season/{season_number}.
  #
  # Usage:
  #   TheMovieDb::Season.new(tv_id: 1396, season_number: 1).results
  #   => { "id" => 3572, "name" => "Season 1", "episodes" => [...], ... }
  class Season < Base
    # @rbs @tv_id: Integer
    # @rbs @season_number: Integer

    #: (tv_id: Integer, season_number: Integer, ?api_key: String?, ?language: String?) -> void
    def initialize(tv_id:, season_number:, api_key: nil, language: nil)
      super(api_key: api_key, language: language)
      @tv_id = tv_id           #: Integer
      @season_number = season_number #: Integer
    end

    private

    #: () -> String
    def path
      "tv/#{@tv_id}/season/#{@season_number}"
    end
  end
end
