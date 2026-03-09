# frozen_string_literal: true

module TheMovieDb
  module Search
    class Movie < Base
      option :year, type: Types::Coercible::Integer.optional, optional: true
      option :primary_release_year, type: Types::Coercible::Integer.optional, optional: true

      def next_page
        @next_page ||= self.class.new(page: page + 1, query:, language:, year:, primary_release_year:)
      end

      def previous_page
        @previous_page ||= self.class.new(page: [ page - 1, 1 ].max, query:, language:, year:, primary_release_year:)
      end
    end
  end
end
