# frozen_string_literal: true

require 'test_helper'

class SearchMultiQueryTest < ActiveSupport::TestCase
  SEARCH_MULTI_QUERY = <<~GQL
    query SearchMulti($query: String!, $page: Int, $language: String) {
      searchMulti(query: $query, page: $page, language: $language) {
        page
        totalPages
        totalResults
        results {
          id
          mediaType
          displayTitle
          title
          name
          releaseDate
          firstAirDate
          overview
          posterPath
          popularity
          voteAverage
          voteCount
          adult
          video
          originalLanguage
          genreIds
        }
      }
    }
  GQL

  SEARCH_WITH_VIDEO_BLOBS_QUERY = <<~GQL
    query SearchMulti($query: String!) {
      searchMulti(query: $query) {
        results {
          id
          mediaType
          videoBlobs {
            id
            filename
            mediaType
            tmdbId
          }
        }
      }
    }
  GQL

  # -- Fixtures --------------------------------------------------------------

  def movie_results
    [
      {
        'id' => 27_205,
        'title' => 'Inception',
        'overview' => 'A thief who steals corporate secrets via dream invasion.',
        'popularity' => 150.0,
        'vote_average' => 8.8,
        'vote_count' => 35_000,
        'adult' => false,
        'video' => false,
        'original_language' => 'en',
        'genre_ids' => [28, 878],
        'poster_path' => '/inception.jpg',
        'backdrop_path' => nil,
        'release_date' => '2010-07-16'
      },
      {
        'id' => 99_999,
        'title' => 'Inception 2',
        'overview' => 'Sequel.',
        'popularity' => 50.0,
        'vote_average' => 6.0,
        'vote_count' => 1000,
        'adult' => false,
        'video' => false,
        'original_language' => 'en',
        'genre_ids' => [28],
        'poster_path' => nil,
        'backdrop_path' => nil,
        'release_date' => '2020-01-01'
      }
    ]
  end

  def tv_results
    [
      {
        'id' => 1396,
        'name' => 'Breaking Bad',
        'overview' => 'A chemistry teacher turned drug lord.',
        'popularity' => 200.0,
        'vote_average' => 9.5,
        'vote_count' => 12_000,
        'adult' => false,
        'original_language' => 'en',
        'genre_ids' => [18, 80],
        'poster_path' => '/breaking_bad.jpg',
        'backdrop_path' => nil,
        'first_air_date' => '2008-01-20'
      }
    ]
  end

  # -- Fake search class helpers --------------------------------------------

  # Stubs TheMovieDb::Search::Movie.new and TheMovieDb::Search::Tv.new for the duration of the block.
  # Pass recorder lambdas to capture the kwargs passed to .new.
  def with_fake_searches(movie_response:, tv_response:, movie_recorder: nil, tv_recorder: nil)
    movie_stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| movie_response } }
    tv_stub    = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| tv_response } }

    TheMovieDb::Search::Movie.define_singleton_method(:new) do |**kwargs|
      movie_recorder&.call(kwargs)
      movie_stub
    end
    TheMovieDb::Search::Tv.define_singleton_method(:new) do |**kwargs|
      tv_recorder&.call(kwargs)
      tv_stub
    end

    yield
  ensure
    TheMovieDb::Search::Movie.singleton_class.remove_method(:new)
    TheMovieDb::Search::Tv.singleton_class.remove_method(:new)
  end

  # Stubs both search classes to raise the given error when results is called.
  def with_fake_error_searches(error)
    error_stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| raise error } }
    TheMovieDb::Search::Movie.define_singleton_method(:new) { |**_| error_stub }
    TheMovieDb::Search::Tv.define_singleton_method(:new)    { |**_| error_stub }
    yield
  ensure
    TheMovieDb::Search::Movie.singleton_class.remove_method(:new)
    TheMovieDb::Search::Tv.singleton_class.remove_method(:new)
  end

  def default_movie_response
    { 'page' => 1, 'results' => movie_results, 'total_pages' => 3, 'total_results' => 50 }
  end

  def default_tv_response
    { 'page' => 1, 'results' => tv_results, 'total_pages' => 2, 'total_results' => 30 }
  end

  # -- Helpers ---------------------------------------------------------------

  # Returns a GraphQL context hash with a fake Doorkeeper token holding the given scopes.
  # Used when calling ReelixManagerSchema.execute directly (unit-style tests that bypass
  # the HTTP layer and therefore skip controller-level auth).
  def graphql_context(scopes: 'search')
    fake_token = Object.new.tap do |t|
      scope_list = scopes.split
      t.define_singleton_method(:includes_scope?) { |s| scope_list.include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  # -- Tests -----------------------------------------------------------------

  test 'returns merged results with correct pagination metadata' do
    with_fake_searches(movie_response: default_movie_response, tv_response: default_tv_response) do
      result = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'inception' },
                                                               context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      data = result.dig('data', 'searchMulti')
      assert_equal 1,  data['page']
      assert_equal 3,  data['totalPages']    # max(3, 2)
      assert_equal 80, data['totalResults']  # 50 + 30
      assert_equal 3,  data['results'].size  # 2 movies + 1 tv
    end
  end

  test 'results include correct mediaType tags for movies and tv' do
    with_fake_searches(movie_response: default_movie_response, tv_response: default_tv_response) do
      result  = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'inception' },
                                                                context: graphql_context)
      results = result.dig('data', 'searchMulti', 'results')

      assert_includes results.map { |r| r['mediaType'] }, 'movie'
      assert_includes results.map { |r| r['mediaType'] }, 'tv'
    end
  end

  test 'exact-match title ranks first' do
    with_fake_searches(movie_response: default_movie_response, tv_response: default_tv_response) do
      result  = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'Inception' },
                                                                context: graphql_context)
      results = result.dig('data', 'searchMulti', 'results')

      assert_equal 'Inception', results.first['displayTitle']
    end
  end

  test 'displayTitle uses name for TV shows' do
    with_fake_searches(movie_response: default_movie_response, tv_response: default_tv_response) do
      result  = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'breaking bad' },
                                                                context: graphql_context)
      results = result.dig('data', 'searchMulti', 'results')
      tv      = results.find { |r| r['mediaType'] == 'tv' }

      assert_equal 'Breaking Bad', tv['displayTitle']
    end
  end

  test 'page argument is forwarded to search classes' do
    movie_kwargs = nil
    tv_kwargs    = nil
    with_fake_searches(
      movie_response: default_movie_response.merge('page' => 2),
      tv_response: default_tv_response.merge('page' => 2),
      movie_recorder: ->(kwargs) { movie_kwargs = kwargs },
      tv_recorder: ->(kwargs) { tv_kwargs = kwargs }
    ) do
      result = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'test', page: 2 },
                                                               context: graphql_context)

      assert_nil result['errors']
      assert_equal 2, result.dig('data', 'searchMulti', 'page')
      assert_equal 2, movie_kwargs[:page]
      assert_equal 2, tv_kwargs[:page]
    end
  end

  test 'language argument is forwarded to search classes' do
    movie_kwargs = nil
    tv_kwargs    = nil
    with_fake_searches(
      movie_response: default_movie_response,
      tv_response: default_tv_response,
      movie_recorder: ->(kwargs) { movie_kwargs = kwargs },
      tv_recorder: ->(kwargs) { tv_kwargs = kwargs }
    ) do
      ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'test', language: 'fr-FR' },
                                                      context: graphql_context)

      assert_equal 'fr-FR', movie_kwargs[:language]
      assert_equal 'fr-FR', tv_kwargs[:language]
    end
  end

  test 'returns GraphQL error on TMDB authentication failure' do
    Thread.report_on_exception = false
    with_fake_error_searches(TheMovieDb::InvalidConfig.new('bad key')) do
      result = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'test' },
                                                               context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('authentication') })
    end
  ensure
    Thread.report_on_exception = true
  end

  test 'returns GraphQL error on TMDB API error' do
    # Build a minimal fake Faraday response to exercise the TheMovieDb::Error rescue path.
    fake_env      = Struct.new(:url).new(URI('https://api.themoviedb.org/3/search/movie'))
    fake_response = Struct.new(:body, :status, :env).new(
      '{"status_message":"service unavailable"}', 503, fake_env
    )
    Thread.report_on_exception = false
    with_fake_error_searches(TheMovieDb::Error.new(fake_response)) do
      result = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'test' },
                                                               context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('TMDB service error') })
    end
  ensure
    Thread.report_on_exception = true
  end

  test 'empty results are handled gracefully' do
    with_fake_searches(
      movie_response: { 'page' => 1, 'results' => [], 'total_pages' => 0, 'total_results' => 0 },
      tv_response: { 'page' => 1, 'results' => [], 'total_pages' => 0, 'total_results' => 0 }
    ) do
      result = ReelixManagerSchema.execute(SEARCH_MULTI_QUERY, variables: { query: 'xyzzy' },
                                                               context: graphql_context)

      assert_nil result['errors']
      data = result.dig('data', 'searchMulti')
      assert_equal [], data['results']
      assert_equal 0,  data['totalResults']
    end
  end

  # -- videoBlobs field -------------------------------------------------------

  test 'returns matched video blobs for a movie search result' do
    movie_response = { 'page' => 1, 'results' => [movie_results.first], 'total_pages' => 1, 'total_results' => 1 }
    with_fake_searches(movie_response: movie_response, tv_response: default_tv_response) do
      result = ReelixManagerSchema.execute(SEARCH_WITH_VIDEO_BLOBS_QUERY, variables: { query: 'inception' },
                                                                          context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      results      = result.dig('data', 'searchMulti', 'results')
      inception    = results.find { |r| r['id'] == 27_205 && r['mediaType'] == 'movie' }

      assert_equal 1, inception['videoBlobs'].size
      assert_equal video_blobs(:inception).filename, inception['videoBlobs'].first['filename']
      assert_equal 'movie', inception['videoBlobs'].first['mediaType']
    end
  end

  test 'returns matched video blobs for a TV show search result' do
    tv_response = { 'page' => 1, 'results' => [tv_results.first.merge('media_type' => 'tv')], 'total_pages' => 1,
                    'total_results' => 1 }
    with_fake_searches(movie_response: default_movie_response, tv_response: tv_response) do
      result = ReelixManagerSchema.execute(SEARCH_WITH_VIDEO_BLOBS_QUERY, variables: { query: 'breaking bad' },
                                                                          context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      results      = result.dig('data', 'searchMulti', 'results')
      breaking_bad = results.find { |r| r['id'] == 1396 && r['mediaType'] == 'tv' }

      assert_equal 1, breaking_bad['videoBlobs'].size
      assert_equal video_blobs(:breaking_bad_s01e01).filename, breaking_bad['videoBlobs'].first['filename']
    end
  end

  test 'returns empty videoBlobs for a result with no local file' do
    movie_response = { 'page' => 1, 'results' => [movie_results.last], 'total_pages' => 1, 'total_results' => 1 }
    with_fake_searches(movie_response: movie_response,
                       tv_response: { 'page' => 1, 'results' => [], 'total_pages' => 0,
                                      'total_results' => 0 }) do
      result = ReelixManagerSchema.execute(SEARCH_WITH_VIDEO_BLOBS_QUERY, variables: { query: 'inception 2' },
                                                                          context: graphql_context)

      assert_nil result['errors']
      results    = result.dig('data', 'searchMulti', 'results')
      inception2 = results.find { |r| r['id'] == 99_999 }

      assert_empty inception2['videoBlobs']
    end
  end

  test 'batches videoBlobs lookups for all search results in one query' do
    with_fake_searches(movie_response: default_movie_response, tv_response: default_tv_response) do
      query_count = count_sql_queries do
        ReelixManagerSchema.execute(SEARCH_WITH_VIDEO_BLOBS_QUERY, variables: { query: 'inception' },
                                                                   context: graphql_context)
      end

      assert_equal 1, query_count, 'expected one SQL query for all videoBlobs in the search results'
    end
  end
end
