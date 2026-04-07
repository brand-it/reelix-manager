# frozen_string_literal: true

require "test_helper"

class KeyParserServiceTest < ActiveSupport::TestCase
  MOVIE_PATH = "/movies"
  TV_PATH    = "/tv"

  def call(path)
    KeyParserService.call(path, movie_path: MOVIE_PATH, tv_path: TV_PATH)
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
    assert_equal "video/x-matroska", result.content_type
  end

  test "parses movie with edition" do
    result = call("/movies/The Lord of the Rings The Fellowship of the Ring (2001) {edition-Extended}/The Lord of the Rings The Fellowship of the Ring (2001) {edition-Extended}.mkv")
    assert result.movie?
    assert_equal "Extended", result.edition
    assert_equal 2001, result.year
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
    result = call("/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - S01E01 - Pilot.mkv")
    assert result.tv?
    assert_equal "Breaking Bad", result.title
    assert_equal 2008, result.year
    assert_equal 1,    result.season
    assert_equal 1,    result.episode
  end

  test "parses TV multi-episode file" do
    result = call("/tv/The Office (2005)/Season 02/The Office (2005) - S02E01-E02 - Diversity Day.mkv")
    assert result.tv?
    assert_equal 1, result.episode
    assert_equal 2, result.episode_last
  end

  test "parses TV with only number in filename" do
    result = call("/tv/Some Show/S03E05.mkv")
    assert result.tv?
    assert_equal 3, result.season
    assert_equal 5, result.episode
  end

  test "TV show is not movie?" do
    result = call("/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - S01E01 - Pilot.mkv")
    assert_not result.movie?
  end
end
