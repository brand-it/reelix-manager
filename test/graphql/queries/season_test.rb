require "test_helper"

class SeasonQueryTest < ActiveSupport::TestCase
  SEASON_QUERY = <<~GQL
    query Season($tvId: Int!, $seasonNumber: Int!, $language: String) {
      season(tvId: $tvId, seasonNumber: $seasonNumber, language: $language) {
        id
        name
        overview
        airDate
        seasonNumber
        posterPath
        voteAverage
        episodes {
          id
          name
          overview
          airDate
          episodeNumber
          episodeType
          productionCode
          runtime
          seasonNumber
          showId
          stillPath
          voteAverage
          voteCount
        }
      }
    }
  GQL

  SEASON_WITH_VIDEO_BLOBS_QUERY = <<~GQL
    query Season($tvId: Int!, $seasonNumber: Int!) {
      season(tvId: $tvId, seasonNumber: $seasonNumber) {
        episodes {
          episodeNumber
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

  def season_data
    {
      "id" => 3572,
      "name" => "Season 1",
      "overview" => "First season overview.",
      "air_date" => "2008-01-20",
      "season_number" => 1,
      "poster_path" => "/s1.jpg",
      "vote_average" => 8.5,
      "episodes" => [
        {
          "id" => 62085,
          "name" => "Pilot",
          "overview" => "Walter White begins his transformation.",
          "air_date" => "2008-01-20",
          "episode_number" => 1,
          "episode_type" => "standard",
          "production_code" => "",
          "runtime" => 58,
          "season_number" => 1,
          "show_id" => 1396,
          "still_path" => "/pilot.jpg",
          "vote_average" => 8.9,
          "vote_count" => 2500
        },
        {
          "id" => 62086,
          "name" => "Cat's in the Bag",
          "overview" => "Walt and Jesse must deal with a difficult situation.",
          "air_date" => "2008-01-27",
          "episode_number" => 2,
          "episode_type" => "standard",
          "production_code" => nil,
          "runtime" => 48,
          "season_number" => 1,
          "show_id" => 1396,
          "still_path" => nil,
          "vote_average" => 8.2,
          "vote_count" => 1800
        }
      ]
    }
  end

  # -- Helpers ---------------------------------------------------------------

  def with_fake_season(response)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| response } }
    TheMovieDb::Season.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Season.singleton_class.remove_method(:new)
  end

  def with_fake_season_error(error)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| raise error } }
    TheMovieDb::Season.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Season.singleton_class.remove_method(:new)
  end

  def graphql_context(scopes: "search")
    fake_token = Object.new.tap do |t|
      scope_list = scopes.split
      t.define_singleton_method(:includes_scope?) { |s| scope_list.include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  # -- Tests -----------------------------------------------------------------

  test "returns season fields correctly" do
    with_fake_season(season_data) do
      result = ReelixManagerSchema.execute(
        SEASON_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )

      assert_nil result["errors"], result["errors"].inspect
      season = result.dig("data", "season")
      assert_equal 3572,        season["id"]
      assert_equal "Season 1",  season["name"]
      assert_equal 1,           season["seasonNumber"]
      assert_equal 8.5,         season["voteAverage"]
      assert_equal "2008-01-20", season["airDate"]
    end
  end

  test "returns episodes as nested objects" do
    with_fake_season(season_data) do
      result = ReelixManagerSchema.execute(
        SEASON_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )

      assert_nil result["errors"]
      episodes = result.dig("data", "season", "episodes")
      assert_equal 2,             episodes.size
      assert_equal "Pilot",       episodes.first["name"]
      assert_equal 1,             episodes.first["episodeNumber"]
      assert_equal 58,            episodes.first["runtime"]
      assert_equal 1396,          episodes.first["showId"]
      assert_equal 8.9,           episodes.first["voteAverage"]
    end
  end

  test "returns GraphQL error on TMDB authentication failure" do
    with_fake_season_error(TheMovieDb::InvalidConfig.new("bad key")) do
      result = ReelixManagerSchema.execute(
        SEASON_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )
      assert result["errors"].any? { |e| e["message"].include?("authentication") }
    end
  end

  test "returns GraphQL error on TMDB API error" do
    fake_env      = Struct.new(:url).new(URI("https://api.themoviedb.org/3/tv/1396/season/1"))
    fake_response = Struct.new(:body, :status, :env).new(
      '{"status_message":"not found"}', 404, fake_env
    )
    with_fake_season_error(TheMovieDb::Error.new(fake_response)) do
      result = ReelixManagerSchema.execute(
        SEASON_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )
      assert result["errors"].any? { |e| e["message"].include?("TMDB service error") }
    end
  end

  test "requires search scope" do
    with_fake_season(season_data) do
      result = ReelixManagerSchema.execute(
        SEASON_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context(scopes: "upload")
      )
      assert result["errors"].any? { |e| e["message"].include?("Forbidden") }
    end
  end

  # -- videoBlobs field -------------------------------------------------------

  test "returns matched video blobs for an episode" do
    with_fake_season(season_data) do
      result = ReelixManagerSchema.execute(
        SEASON_WITH_VIDEO_BLOBS_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )

      assert_nil result["errors"], result["errors"].inspect
      episodes = result.dig("data", "season", "episodes")
      pilot    = episodes.find { |e| e["episodeNumber"] == 1 }

      assert_equal 1, pilot["videoBlobs"].size
      assert_equal video_blobs(:breaking_bad_s01e01).filename, pilot["videoBlobs"].first["filename"]
      assert_equal "tv",  pilot["videoBlobs"].first["mediaType"]
      assert_equal 1396,  pilot["videoBlobs"].first["tmdbId"]
    end
  end

  test "returns empty videoBlobs for an episode without a local file" do
    with_fake_season(season_data) do
      result = ReelixManagerSchema.execute(
        SEASON_WITH_VIDEO_BLOBS_QUERY,
        variables: { tvId: 1396, seasonNumber: 1 },
        context: graphql_context
      )

      assert_nil result["errors"]
      episodes = result.dig("data", "season", "episodes")
      ep2      = episodes.find { |e| e["episodeNumber"] == 2 }

      assert_empty ep2["videoBlobs"]
    end
  end

  test "batches episode blob lookups across all episodes in one season query" do
    with_fake_season(season_data) do
      query_count = count_sql_queries do
        ReelixManagerSchema.execute(
          SEASON_WITH_VIDEO_BLOBS_QUERY,
          variables: { tvId: 1396, seasonNumber: 1 },
          context: graphql_context
        )
      end

      assert_equal 1, query_count, "expected one SQL query for all episode blobs in the season"
    end
  end
end
