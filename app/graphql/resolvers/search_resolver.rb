# frozen_string_literal: true

module Resolvers
  # Resolves a combined movie + TV show search against TMDB.
  #
  # Both /search/movie and /search/tv are called in parallel for the given page.
  # Results are merged and re-ranked using a composite score:
  #   score = keyword_score * 0.6 + popularity_score * 0.4
  #
  # keyword_score (0.0–1.0):
  #   1.0  exact title match
  #   0.9  title starts with query
  #   0.7  title contains query as a substring
  #   0.0–0.5  proportional word-level match
  #
  # popularity_score (0.0–1.0):
  #   TMDB popularity normalized against a practical ceiling of 1000
  class SearchResolver < Resolvers::BaseResolver
    type Types::SearchResponseType, null: false

    argument :query, String, required: true, description: "Search term for movies and TV shows"
    argument :page, Integer, required: false, default_value: 1,
      description: "Page number (1–500, default 1)"
    argument :language, String, required: false, default_value: "en-US",
      description: "BCP 47 language tag for results (default en-US)"

    MAX_PAGE = 500

    #: (query: String, page: Integer, language: String) -> ::Hash[Symbol, untyped]
    def resolve(query:, page:, language:)
      require_search!
      page = page.clamp(1, MAX_PAGE)

      movie_response, tv_response = fetch_both(query, page, language)

      movie_results = tag_media_type(movie_response["results"] || [], "movie")
      tv_results    = tag_media_type(tv_response["results"] || [],    "tv")

      merged = merge_and_rank(movie_results + tv_results, query)

      {
        results: merged,
        page: page,
        total_pages: [ movie_response["total_pages"].to_i, tv_response["total_pages"].to_i ].max,
        total_results: movie_response["total_results"].to_i + tv_response["total_results"].to_i
      }
    rescue TheMovieDb::InvalidConfig => e
      Rails.logger.error("[TMDB InvalidConfig] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, "TMDB authentication error. Please contact support."
    rescue TheMovieDb::Error => e
      Rails.logger.error("[TMDB Error] #{sanitize_error_message(e.message)}")
      raise GraphQL::ExecutionError, "TMDB service error. Please try again later."
    end

    private

    # Run both API calls concurrently. Thread#value re-raises any exception from the thread.
    # Threads are wrapped with Rails.application.executor and connection_pool.with_connection
    # to prevent AR connection leaks when Config::Video is accessed inside the thread.
    #: (String query, Integer page, String language) -> [untyped, untyped]
    def fetch_both(query, page, language)
      movie_thread = Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection do
            TheMovieDb::Search::Movie.new(query:, page:, language:).results(use_cache: false)
          end
        end
      end
      tv_thread = Thread.new do
        Rails.application.executor.wrap do
          ActiveRecord::Base.connection_pool.with_connection do
            TheMovieDb::Search::Tv.new(query:, page:, language:).results(use_cache: false)
          end
        end
      end
      [ movie_thread.value, tv_thread.value ]
    end

    # Ensure every result has an explicit media_type field.
    #: (::Array[::Hash[String, untyped]] results, String type) -> ::Array[::Hash[String, untyped]]
    def tag_media_type(results, type)
      results.map { |r| r.merge("media_type" => type) }
    end

    # Merge results and sort by composite relevance score (descending).
    #: (::Array[::Hash[String, untyped]] results, String query) -> ::Array[::Hash[String, untyped]]
    def merge_and_rank(results, query)
      normalized_query = query.downcase.strip
      results.sort_by { |r| -composite_score(r, normalized_query) }
    end

    # Composite relevance score (0.0–1.0).
    #: (::Hash[String, untyped] result, String query) -> Float
    def composite_score(result, query)
      kw_score  = keyword_score(result_title(result), query)
      pop_score = popularity_score(result["popularity"].to_f)
      (kw_score * 0.6) + (pop_score * 0.4)
    end

    # Normalised popularity score capped at 1.0.
    # TMDB popularity values can reach into the thousands for blockbusters.
    POPULARITY_CEILING = 1000.0

    #: (Float popularity) -> Float
    def popularity_score(popularity)
      (popularity / POPULARITY_CEILING).clamp(0.0, 1.0)
    end

    # Keyword similarity score (0.0–1.0) based on the result title vs. query.
    #: (String? title, String query) -> Float
    def keyword_score(title, query)
      return 0.0 if title.blank? || query.blank?

      title_norm = title.downcase

      return 1.0 if title_norm == query
      return 0.9 if title_norm.start_with?(query)
      return 0.7 if title_norm.include?(query)

      word_match_score(title_norm, query)
    end

    # Proportional word-level match (0.0–0.5).
    # Scores based on how many query words have a prefix match in the title.
    #: (String title, String query) -> Float
    def word_match_score(title, query)
      query_words = query.split
      return 0.0 if query_words.empty?

      title_words = title.split
      matched = query_words.count do |qw|
        title_words.any? { |tw| tw.start_with?(qw) || qw.start_with?(tw) }
      end

      (matched.to_f / query_words.size) * 0.5
    end

    #: (::Hash[String, untyped] result) -> String
    def result_title(result)
      result["title"] || result["name"] || ""
    end

    #: (String? message) -> String
    def sanitize_error_message(message)
      return "" if message.nil?

      message.dup
             .gsub(/api_key=[^&\s]*/i, "api_key=[REDACTED]")
             .gsub(/(Bearer\s+)[A-Za-z0-9\-._]+/i, '\1[REDACTED]')
    end
  end
end
