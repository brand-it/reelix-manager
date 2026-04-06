# frozen_string_literal: true

module TheMovieDb
  module Search
    class Movie < Base
      attr_reader :year, :primary_release_year

      # @rbs @year: Integer?
      # @rbs @primary_release_year: Integer?

      #: (query: String, ?page: Integer, ?api_key: String?, ?language: String?, ?year: Integer?, ?primary_release_year: Integer?) -> void
      def initialize(query:, page: 1, api_key: nil, language: nil, year: nil, primary_release_year: nil)
        super(query: query, page: page, api_key: api_key, language: language)
        @year = year&.to_i               #: Integer?
        @primary_release_year = primary_release_year&.to_i #: Integer?
      end

      #: () -> TheMovieDb::Search::Movie
      def next_page
        @next_page ||= self.class.new(page: page + 1, query:, language:, year:, primary_release_year:) #: TheMovieDb::Search::Movie
      end

      #: () -> TheMovieDb::Search::Movie
      def previous_page
        @previous_page ||= self.class.new(page: [ page - 1, 1 ].max, query:, language:, year:, primary_release_year:) #: TheMovieDb::Search::Movie
      end

      private

      #: () -> ::Hash[Symbol | String, String | Integer]
      def query_params
        super.merge(year:, primary_release_year:).compact
      end
    end
  end
end
