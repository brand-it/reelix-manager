# frozen_string_literal: true

require 'test_helper'

class MovieQueryTest < ActiveSupport::TestCase
  MOVIE_QUERY = <<~GQL
    query Movie($id: Int!, $language: String) {
      movie(id: $id, language: $language) {
        id
        title
        originalTitle
        overview
        releaseDate
        adult
        video
        popularity
        voteAverage
        voteCount
        runtime
        budget
        revenue
        originalLanguage
        originCountry
        posterPath
        backdropPath
        status
        tagline
        homepage
        imdbId
        genres {
          id
          name
        }
      }
    }
  GQL

  MOVIE_WITH_VIDEO_BLOBS_QUERY = <<~GQL
    query Movie($id: Int!) {
      movie(id: $id) {
        id
        videoBlobs {
          id
          filename
          mediaType
          tmdbId
        }
      }
    }
  GQL

  # -- Fixtures --------------------------------------------------------------

  def movie_data
    {
      'id' => 27_205,
      'title' => 'Inception',
      'original_title' => 'Inception',
      'overview' => 'A thief who steals corporate secrets via dream invasion.',
      'release_date' => '2010-07-16',
      'adult' => false,
      'video' => false,
      'popularity' => 150.0,
      'vote_average' => 8.8,
      'vote_count' => 35_000,
      'runtime' => 148,
      'budget' => 160_000_000,
      'revenue' => 836_836_967,
      'original_language' => 'en',
      'origin_country' => ['US'],
      'poster_path' => '/inception.jpg',
      'backdrop_path' => nil,
      'status' => 'Released',
      'tagline' => 'Your mind is the scene of the crime.',
      'homepage' => 'https://www.warnerbros.com/movies/inception',
      'imdb_id' => 'tt1375666',
      'genres' => [
        { 'id' => 28, 'name' => 'Action' },
        { 'id' => 878, 'name' => 'Science Fiction' }
      ]
    }
  end

  # -- Helpers ---------------------------------------------------------------

  def with_fake_movie(response)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| response } }
    TheMovieDb::Movie.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Movie.singleton_class.remove_method(:new)
  end

  def with_fake_movie_error(error)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| raise error } }
    TheMovieDb::Movie.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Movie.singleton_class.remove_method(:new)
  end

  def graphql_context(scopes: 'search')
    fake_token = Object.new.tap do |t|
      scope_list = scopes.split
      t.define_singleton_method(:includes_scope?) { |s| scope_list.include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  # -- Tests -----------------------------------------------------------------

  test 'returns movie fields correctly' do
    with_fake_movie(movie_data) do
      result = ReelixManagerSchema.execute(MOVIE_QUERY, variables: { id: 27_205 },
                                                        context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      movie = result.dig('data', 'movie')
      assert_equal 27_205, movie['id']
      assert_equal 'Inception',                       movie['title']
      assert_equal '2010-07-16',                      movie['releaseDate']
      assert_equal 8.8,                               movie['voteAverage']
      assert_equal 148,                               movie['runtime']
      assert_equal 'tt1375666',                       movie['imdbId']
      assert_equal ['US'], movie['originCountry']
    end
  end

  test 'returns genres as nested objects' do
    with_fake_movie(movie_data) do
      result = ReelixManagerSchema.execute(MOVIE_QUERY, variables: { id: 27_205 },
                                                        context: graphql_context)

      genres = result.dig('data', 'movie', 'genres')
      assert_equal 2, genres.size
      assert_equal({ 'id' => 28, 'name' => 'Action' }, genres.first)
    end
  end

  test 'returns GraphQL error on TMDB authentication failure' do
    with_fake_movie_error(TheMovieDb::InvalidConfig.new('bad key')) do
      result = ReelixManagerSchema.execute(MOVIE_QUERY, variables: { id: 27_205 },
                                                        context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('authentication') })
    end
  end

  test 'returns GraphQL error on TMDB API error' do
    fake_env      = Struct.new(:url).new(URI('https://api.themoviedb.org/3/movie/27205'))
    fake_response = Struct.new(:body, :status, :env).new(
      '{"status_message":"not found"}', 404, fake_env
    )
    with_fake_movie_error(TheMovieDb::Error.new(fake_response)) do
      result = ReelixManagerSchema.execute(MOVIE_QUERY, variables: { id: 27_205 },
                                                        context: graphql_context)
      assert(result['errors'].any? { |e| e['message'].include?('TMDB service error') })
    end
  end

  test 'requires search scope' do
    with_fake_movie(movie_data) do
      result = ReelixManagerSchema.execute(MOVIE_QUERY, variables: { id: 27_205 },
                                                        context: graphql_context(scopes: 'upload'))
      assert(result['errors'].any? { |e| e['message'].include?('Forbidden') })
    end
  end

  # -- videoBlobs field -------------------------------------------------------

  test 'returns matched video blobs for a movie' do
    with_fake_movie(movie_data) do
      result = ReelixManagerSchema.execute(MOVIE_WITH_VIDEO_BLOBS_QUERY, variables: { id: 27_205 },
                                                                         context: graphql_context)

      assert_nil result['errors'], result['errors'].inspect
      blobs = result.dig('data', 'movie', 'videoBlobs')
      assert_equal 1, blobs.size
      assert_equal video_blobs(:inception).filename, blobs.first['filename']
      assert_equal 'movie',                          blobs.first['mediaType']
      assert_equal 27_205, blobs.first['tmdbId']
    end
  end

  test 'returns empty videoBlobs when no local file matches the movie' do
    with_fake_movie(movie_data.merge('id' => 99_999)) do
      result = ReelixManagerSchema.execute(MOVIE_WITH_VIDEO_BLOBS_QUERY, variables: { id: 99_999 },
                                                                         context: graphql_context)

      assert_nil result['errors']
      assert_empty result.dig('data', 'movie', 'videoBlobs')
    end
  end
end
