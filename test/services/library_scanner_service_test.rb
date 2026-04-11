# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class LibraryScannerServiceTest < ActiveSupport::TestCase
  setup do
    VideoBlob.delete_all  # prevent fixture blobs from being pruned as stale
    @tmpdir   = Dir.mktmpdir("library_scanner_test")
    @movie_dir = File.join(@tmpdir, "movies")
    @tv_dir    = File.join(@tmpdir, "tv")
    FileUtils.mkdir_p(@movie_dir)
    FileUtils.mkdir_p(@tv_dir)

    @config = Config::Video.new
    @config.settings = {
      movie_path:     @movie_dir,
      tv_path:        @tv_dir,
      tmdb_api_key:   "test_key_123",
      processed_path: @tmpdir
    }
    @config.save!(validate: false)
  end

  teardown do
    FileUtils.remove_entry(@tmpdir)
    VideoBlob.delete_all
    Config::Video.delete_all
  end

  # ---------------------------------------------------------------------------
  # Adding new blobs
  # ---------------------------------------------------------------------------

  test "creates VideoBlob for each discovered mkv" do
    mkv = add_movie_file("Inception (2010)", "Inception (2010).mkv")

    stats = LibraryScannerService.call

    assert_equal 1, stats[:added]
    assert_equal 0, stats[:updated]
    assert_equal 0, stats[:removed]
    assert VideoBlob.exists?(key: mkv)
  end

  test "stores correct attributes on movie blob" do
    add_movie_file("Inception (2010)", "Inception (2010).mkv")

    LibraryScannerService.call

    blob = VideoBlob.find_by(title: "Inception")
    assert_not_nil blob
    assert blob.movie?
    assert_equal 2010, blob.year
    assert_equal "mkv", blob.path_extension
    assert_nil blob.episode_title
    assert_equal "video/x-matroska", blob.content_type
  end

  test "stores correct attributes on tv blob" do
    add_tv_file("Breaking Bad (2008)", "Season 01", "Breaking Bad (2008) - S01E01 - Pilot.mkv")

    LibraryScannerService.call

    blob = VideoBlob.find_by(title: "Breaking Bad")
    assert_not_nil blob
    assert blob.tv?
    assert_equal 1, blob.season_number
    assert_equal 1, blob.episode_number
    assert_equal "Pilot", blob.episode_title
    assert_equal "mkv", blob.path_extension
  end

  test "build_attrs stores nil path_extension when filename has no extension" do
    blob_data = KeyParserService::BlobData.new(
      content_type: nil,
      edition: nil,
      episode_last: nil,
      episode: nil,
      episode_title: nil,
      extra_number: nil,
      extra_type: nil,
      extra: false,
      filename: "Inception (2010)",
      optimized: false,
      part: nil,
      plex_version: false,
      season: nil,
      title: "Inception",
      type: "Movie",
      year: 2010
    )

    attrs = LibraryScannerService.new.send(:build_attrs, blob_data)

    assert_nil attrs[:path_extension]
  end

  # ---------------------------------------------------------------------------
  # Updating existing blobs
  # ---------------------------------------------------------------------------

  test "updates existing blob when file is re-scanned" do
    mkv = add_movie_file("Inception (2010)", "Inception (2010).mkv")
    LibraryScannerService.call

    blob = VideoBlob.find_by(key: mkv)
    original_updated_at = blob.updated_at

    # Touch the config to invalidate cache, then re-scan
    stats = LibraryScannerService.call

    assert_equal 0, stats[:added]
    assert_equal 1, stats[:updated]
  end

  # ---------------------------------------------------------------------------
  # Pruning stale blobs
  # ---------------------------------------------------------------------------

  test "removes VideoBlob when file is deleted" do
    mkv = add_movie_file("Old Movie (2000)", "Old Movie (2000).mkv")
    LibraryScannerService.call
    assert VideoBlob.exists?(key: mkv)

    FileUtils.rm(mkv)
    stats = LibraryScannerService.call

    assert_equal 1, stats[:removed]
    assert_not VideoBlob.exists?(key: mkv)
  end

  # ---------------------------------------------------------------------------
  # Skipping non-video files
  # ---------------------------------------------------------------------------

  test "skips non-video files" do
    dir = File.join(@movie_dir, "Inception (2010)")
    FileUtils.mkdir_p(dir)
    File.write(File.join(dir, "cover.jpg"), "fake image")

    stats = LibraryScannerService.call

    assert_equal 0, stats[:added]
    assert_equal 1, stats[:skipped]
  end

  # ---------------------------------------------------------------------------
  # Missing config
  # ---------------------------------------------------------------------------

  test "returns empty stats when Config::Video is missing" do
    VideoBlob.delete_all
    Config::Video.delete_all

    stats = LibraryScannerService.call

    assert_equal({ added: 0, updated: 0, removed: 0, skipped: 0 }, stats)
  end

  private

  def add_movie_file(movie_dir, filename)
    dir = File.join(@movie_dir, movie_dir)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, filename)
    FileUtils.touch(path)
    path
  end

  def add_tv_file(show_dir, season_dir, filename)
    dir = File.join(@tv_dir, show_dir, season_dir)
    FileUtils.mkdir_p(dir)
    path = File.join(dir, filename)
    FileUtils.touch(path)
    path
  end
end
