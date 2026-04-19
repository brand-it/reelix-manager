# frozen_string_literal: true

require 'test_helper'

class TvQueryTest < ActiveSupport::TestCase
  TV_QUERY = <<~GQL
    query Tv($id: Int!, $language: String) {
      tv(id: $id, language: $language) {
        id
        name
        originalName
        overview
        firstAirDate
        lastAirDate
        inProduction
        adult
        popularity
        voteAverage
        voteCount
        numberOfSeasons
        numberOfEpisodes
        episodeRunTime
        originalLanguage
        languages
        originCountry
        posterPath
        backdropPath
        status
        tagline
        homepage
        showType
        genres {
          id
          name
        }
        seasons {
          id
          name
          seasonNumber
          episodeCount
          airDate
          voteAverage
        }
      }
    }
  GQL

  # -- Fixtures --------------------------------------------------------------

  def tv_data
    {
      'id' => 1396,
      'name' => 'Breaking Bad',
      'original_name' => 'Breaking Bad',
      'overview' => 'A chemistry teacher turned drug lord.',
      'first_air_date' => '2008-01-20',
      'last_air_date' => '2013-09-29',
      'in_production' => false,
      'adult' => false,
      'popularity' => 200.0,
      'vote_average' => 9.5,
      'vote_count' => 12_000,
      'number_of_seasons' => 5,
      'number_of_episodes' => 62,
      'episode_run_time' => [47, 48],
      'original_language' => 'en',
      'languages' => ['en'],
      'origin_country' => ['US'],
      'poster_path' => '/breaking_bad.jpg',
      'backdrop_path' => nil,
      'status' => 'Ended',
      'tagline' => 'All Hail the King',
      'homepage' => 'https://www.amc.com/shows/breaking-bad',
      'type' => 'Scripted',
      'genres' => [
        { 'id' => 18, 'name' => 'Drama' },
        { 'id' => 80, 'name' => 'Crime' }
      ],
      'seasons' => [
        {
          'id' => 3572,
          'name' => 'Season 1',
          'season_number' => 1,
          'episode_count' => 7,
          'air_date' => '2008-01-20',
          'overview' => 'First season overview.',
          'poster_path' => nil,
          'vote_average' => 8.5
        }
      ]
    }
  end

  # -- Helpers ---------------------------------------------------------------

  def with_fake_tv(response)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| response } }
    TheMovieDb::Tv.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Tv.singleton_class.remove_method(:new)
  end

  def with_fake_tv_error(error)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| raise error } }
    TheMovieDb::Tv.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Tv.singleton_class.remove_method(:new)
  end

  def graphql_context(scopes: 'search')
    fake_token = Object.new.tap do |t|
      scope_list = scopes.split
      t.define_singleton_method(:includes_scope?) { |s| scope_list.include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  # -- Tests -----------------------------------------------------------------

  test 'returns TV show fields correctly' do
    with_fake_tv(tv_data) do
      result = ReelixManagerSchema.execute(TV_QUERY, variables: { id: 1396 },
                                                     context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      tv = result.dig('data', 'tv')
      assert_equal 1396,             tv['id']
      assert_equal 'Breaking Bad',   tv['name']
      assert_equal '2008-01-20',     tv['firstAirDate']
      assert_equal 5,                tv['numberOfSeasons']
      assert_equal 62,               tv['numberOfEpisodes']
      assert_equal [47, 48], tv['episodeRunTime']
      assert_equal 'Scripted',       tv['showType']
      assert_equal false,            tv['inProduction']
    end
  end

  test 'returns genres and seasons as nested objects' do
    with_fake_tv(tv_data) do
      result = ReelixManagerSchema.execute(TV_QUERY, variables: { id: 1396 },
                                                     context: graphql_context)

      assert_nil result['errors']
      tv = result.dig('data', 'tv')
      assert_equal 2, tv['genres'].size
      assert_equal({ 'id' => 18, 'name' => 'Drama' }, tv['genres'].first)

      assert_equal 1,          tv['seasons'].size
      assert_equal 'Season 1', tv['seasons'].first['name']
      assert_equal 7,          tv['seasons'].first['episodeCount']
    end
  end

  test 'returns GraphQL error on TMDB authentication failure' do
    with_fake_tv_error(TheMovieDb::InvalidConfig.new('bad key')) do
      result = ReelixManagerSchema.execute(TV_QUERY, variables: { id: 1396 },
                                                     context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('authentication') })
    end
  end

  test 'returns GraphQL error on TMDB API error' do
    fake_env      = Struct.new(:url).new(URI('https://api.themoviedb.org/3/tv/1396'))
    fake_response = Struct.new(:body, :status, :env).new(
      '{"status_message":"not found"}', 404, fake_env
    )
    with_fake_tv_error(TheMovieDb::Error.new(fake_response)) do
      result = ReelixManagerSchema.execute(TV_QUERY, variables: { id: 1396 },
                                                     context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('TMDB service error') })
    end
  end

  test 'requires search scope' do
    with_fake_tv(tv_data) do
      result = ReelixManagerSchema.execute(TV_QUERY, variables: { id: 1396 },
                                                     context: graphql_context(scopes: 'upload'))
      assert(result['errors'].any? { |e| e['message'].include?('Forbidden') })
    end
  end
end
