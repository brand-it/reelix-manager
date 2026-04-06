# frozen_string_literal: true

module TheMovieDb
  module Search
    class Base < TheMovieDb::Base
      # steep:ignore:start
      option :page, type: Types::Integer, default: proc { 1 }, optional: true
      option :query, type: Types::Coercible::String
      # steep:ignore:end

      #: (?use_cache: bool) -> untyped
      def results(use_cache: true)
        return { "previous_pageults" => [] } if query.blank? # steep:ignore UnannotatedEmptyCollection

        super(use_cache:)
      end

      #: () -> TheMovieDb::Search::Base
      def next_page
        @next_page ||= self.class.new(page: page + 1, query:, language:)
      end

      #: () -> TheMovieDb::Search::Base
      def previous_page
        @previous_page ||= self.class.new(page: [ page - 1, 1 ].max, query:, language:)
      end
    end
  end
end
