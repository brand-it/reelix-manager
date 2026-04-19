# frozen_string_literal: true

module TheMovieDb
  module Search
    class Base < TheMovieDb::Base
      attr_reader :query, :page

      # @rbs @query: String
      # @rbs @page: Integer
      # @rbs @next_page: TheMovieDb::Search::Base?
      # @rbs @previous_page: TheMovieDb::Search::Base?

      #: (query: String, ?page: Integer, ?api_key: String?, ?language: String?) -> void
      def initialize(query:, page: 1, api_key: nil, language: nil)
        super(api_key: api_key, language: language)
        @query = query.to_s #: String
        @page = page.to_i   #: Integer
      end

      #: (?use_cache: bool) -> ::Hash[String, untyped]
      def results(use_cache: true)
        return { 'results' => [] } if query.blank? # steep:ignore UnannotatedEmptyCollection

        super
      end

      #: () -> TheMovieDb::Search::Base
      def next_page
        @next_page ||= self.class.new(page: page + 1, query:, language:) #: TheMovieDb::Search::Base
      end

      #: () -> TheMovieDb::Search::Base
      def previous_page
        @previous_page ||= self.class.new(page: [page - 1, 1].max, query:, language:) #: TheMovieDb::Search::Base
      end

      private

      #: () -> ::Hash[Symbol | String, String | Integer]
      def query_params
        super.merge(query:, page:)
      end
    end
  end
end
