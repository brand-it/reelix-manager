# frozen_string_literal: true

require "test_helper"

class KeyParserServiceTest < ActiveSupport::TestCase
  MOVIE_PATH = "/movies"
  TV_PATH    = "/tv"

  def call(path)
    KeyParserService.call(path, movie_path: MOVIE_PATH, tv_path: TV_PATH)
  end

  def assert_tv_parse(path, title:, year:, season:, episode:, episode_last: nil)
    result = call(path)

    assert result.tv?, "Expected TV parse for #{path.inspect}"
    assert_equal title,        result.title
    year.nil? ? assert_nil(result.year) : assert_equal(year, result.year)
    season.nil? ? assert_nil(result.season) : assert_equal(season, result.season)
    episode.nil? ? assert_nil(result.episode) : assert_equal(episode, result.episode)
    episode_last.nil? ? assert_nil(result.episode_last) : assert_equal(episode_last, result.episode_last)
    result
  end

  # ---------------------------------------------------------------------------
  # Non-video files
  # ---------------------------------------------------------------------------

  test "returns nil for non-video file" do
    assert_nil call("/movies/Inception (2010)/cover.jpg")
  end

  test "returns nil when path is outside both configured dirs" do
    assert_nil call("/other/Inception (2010)/Inception (2010).mkv")
  end

  # ---------------------------------------------------------------------------
  # Movies
  # ---------------------------------------------------------------------------

  test "parses movie with year" do
    result = call("/movies/Inception (2010)/Inception (2010).mkv")
    assert result.movie?
    assert_equal "Inception", result.title
    assert_equal 2010, result.year
    assert_equal "Inception (2010).mkv", result.filename
    assert_nil result.episode_title
    assert_equal "video/x-matroska", result.content_type
  end

  test "parses movie with edition" do
    result = call("/movies/The Lord of the Rings The Fellowship of the Ring (2001) {edition-Extended}/The Lord of the Rings The Fellowship of the Ring (2001) {edition-Extended}.mkv")
    assert result.movie?
    assert_equal "Extended", result.edition
    assert_equal 2001, result.year
  end

  test "parses movie without year from filename fallback" do
    result = call("/movies/Inception/Inception.mkv")
    assert result.movie?
    assert_equal "Inception", result.title
    assert_nil result.year
  end

  test "parses movie part" do
    result = call("/movies/Gone with the Wind (1939)/Gone with the Wind (1939) part1.mkv")
    assert result.movie?
    assert_equal 1, result.part
  end

  test "parses extra type — featurettes" do
    result = call("/movies/Inception (2010)/Featurettes/Making Of #1.mkv")
    assert result.movie?
    assert_equal :featurettes, result.extra_type
    assert_equal 1, result.extra_number
  end

  test "plex_version detected" do
    result = call("/movies/Inception (2010)/Plex Versions/Inception (2010).mkv")
    assert result.plex_version
  end

  # ---------------------------------------------------------------------------
  # TV shows
  # ---------------------------------------------------------------------------

  test "parses TV episode with season and episode" do
    result = assert_tv_parse(
      "/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - S01E01 - Pilot.mkv",
      title: "Breaking Bad",
      year: 2008,
      season: 1,
      episode: 1
    )
    assert_equal "Pilot", result.episode_title
  end

  test "parses TV episode with date and episode name" do
    result = assert_tv_parse(
      "/tv/Doctor Who (2005)/Season 01/Doctor Who (2005) - S01E01 - 2005-03-26 - Rose.mkv",
      title: "Doctor Who",
      year: 2005,
      season: 1,
      episode: 1
    )
    assert_equal "Rose", result.episode_title
  end

  test "parses TV episode with date but no episode name" do
    assert_tv_parse(
      "/tv/Doctor Who (2005)/Season 01/Doctor Who (2005) - S01E01 - 2005-03-26.mkv",
      title: "Doctor Who",
      year: 2005,
      season: 1,
      episode: 1
    )
  end

  test "parses TV episode without year in filename" do
    assert_tv_parse(
      "/tv/Doctor Who/Season 01/Doctor Who - S01E01 - 2005-03-26 - Rose.mkv",
      title: "Doctor Who",
      year: nil,
      season: 1,
      episode: 1
    )
  end

  test "parses TV episode with air date but no season-episode token" do
    assert_tv_parse(
      "/tv/The Daily Show (1996)/Season 30/The Daily Show (1996) - 2025-01-13 - Guests.mkv",
      title: "The Daily Show",
      year: 1996,
      season: nil,
      episode: nil
    )
  end

  test "parses TV multi-episode file" do
    assert_tv_parse(
      "/tv/The Office (2005)/Season 02/The Office (2005) - S02E01-E02 - Diversity Day.mkv",
      title: "The Office",
      year: 2005,
      season: 2,
      episode: 1,
      episode_last: 2
    )
  end

  test "parses TV with only number in filename" do
    assert_tv_parse(
      "/tv/Some Show/S03E05.mkv",
      title: "Some Show",
      year: nil,
      season: 3,
      episode: 5
    )
  end

  test "TV show is not movie?" do
    result = call("/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - S01E01 - Pilot.mkv")
    assert_not result.movie?
  end
end
