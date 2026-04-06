# frozen_string_literal: true

module TheMovieDb
  module Search
    class Movie < Base
      # steep:ignore:start
      option :year, type: Types::Coercible::Integer.optional, optional: true
      option :primary_release_year, type: Types::Coercible::Integer.optional, optional: true
      # steep:ignore:end

      #: () -> TheMovieDb::Search::Movie
      def next_page
        @next_page ||= self.class.new(page: page + 1, query:, language:, year:, primary_release_year:)
      end

      #: () -> TheMovieDb::Search::Movie
      def previous_page
        @previous_page ||= self.class.new(page: [ page - 1, 1 ].max, query:, language:, year:, primary_release_year:)
      end
    end
  end
end
