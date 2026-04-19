# frozen_string_literal: true

require 'test_helper'

class VideoBlobPathsTest < ActiveSupport::TestCase
  setup do
    @movie_dir = Dir.mktmpdir('video_blob_movie_paths')
    @tv_dir = Dir.mktmpdir('video_blob_tv_paths')
    create(:config_video, movie_dir: @movie_dir, tv_dir: @tv_dir)
  end

  teardown do
    FileUtils.rm_rf(@movie_dir)
    FileUtils.rm_rf(@tv_dir)
    Config::Video.delete_all
  end

  def call(**)
    build_blob(**)
  end

  def build_blob(media_type:, tmdb_id:, title:, year:, extension:, season_number: nil, episode_number: nil,
                 episode_title: nil)
    blob = VideoBlob.new(
      media_type:,
      tmdb_id:,
      title:,
      year:,
      season_number:,
      episode_number:
    )
    blob.path_extension = extension
    blob.episode_title = episode_title
    blob
  end

  # ---------------------------------------------------------------------------
  # Movie paths
  # ---------------------------------------------------------------------------

  test 'movie: builds correct directory' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: 2005, extension: 'mkv')
    assert_equal File.join(@movie_dir, 'Batman Begins (2005)'), result.directory
  end

  test 'movie: builds correct filename' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: 2005, extension: 'mkv')
    assert_equal 'Batman Begins (2005).mkv', result.generated_filename
  end

  test 'movie: media_path joins directory and filename' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: 2005, extension: 'mkv')
    assert_equal File.join(@movie_dir, 'Batman Begins (2005)', 'Batman Begins (2005).mkv'),
                 result.media_path
  end

  test 'movie: strips leading dot from extension' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: 2005, extension: '.mp4')
    assert_equal 'Batman Begins (2005).mp4', result.generated_filename
  end

  test 'movie: extension is lowercased' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: 2005, extension: 'MKV')
    assert result.generated_filename.end_with?('.mkv')
  end

  test 'movie: omits year when nil' do
    result = call(media_type: 'movie', tmdb_id: 272, title: 'Batman Begins', year: nil, extension: 'mkv')
    assert_equal 'Batman Begins', File.basename(result.directory.to_s)
    assert_equal 'Batman Begins.mkv', result.generated_filename
  end

  test 'movie: sanitizes unsafe characters in title' do
    result = call(
      media_type: 'movie',
      tmdb_id: 272,
      title: "  Batman/Begins\\.. \x00  ",
      year: 2005,
      extension: 'mkv'
    )

    assert_equal File.join(@movie_dir, 'Batman-Begins-. (2005)'), result.directory
    assert_equal 'Batman-Begins-. (2005).mkv', result.generated_filename
  end

  # ---------------------------------------------------------------------------
  # TV paths
  # ---------------------------------------------------------------------------

  test 'tv: builds correct directory with season' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 1, episode_number: 1
    )
    assert_equal File.join(@tv_dir, 'Breaking Bad (2008)', 'Season 01'), result.directory
  end

  test 'tv: builds filename with episode title' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 1, episode_number: 1, episode_title: 'Pilot'
    )
    assert_equal 'Breaking Bad (2008) - s01e01 - Pilot.mkv', result.generated_filename
  end

  test 'tv: omits episode title segment when episode_title is nil' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 1, episode_number: 1, episode_title: nil
    )
    assert_equal 'Breaking Bad (2008) - s01e01.mkv', result.generated_filename
  end

  test 'tv: omits episode title segment when episode_title is blank' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 1, episode_number: 1, episode_title: ''
    )
    assert_equal 'Breaking Bad (2008) - s01e01.mkv', result.generated_filename
  end

  test 'tv: omits year when nil' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: nil, extension: 'mkv',
      season_number: 1, episode_number: 1, episode_title: 'Pilot'
    )

    assert_equal File.join(@tv_dir, 'Breaking Bad', 'Season 01'), result.directory
    assert_equal 'Breaking Bad - s01e01 - Pilot.mkv', result.generated_filename
  end

  test 'tv: sanitizes unsafe characters in title and episode title' do
    result = call(
      media_type: 'tv',
      tmdb_id: 1396,
      title: '  Law/Order\\..  ',
      year: 2008,
      extension: 'mkv',
      season_number: 1,
      episode_number: 1,
      episode_title: "  Pilot/Part\\.. \x00 "
    )

    assert_equal File.join(@tv_dir, 'Law-Order-. (2008)', 'Season 01'), result.directory
    assert_equal 'Law-Order-. (2008) - s01e01 - Pilot-Part-..mkv', result.generated_filename
  end

  test 'tv: pads single-digit season number' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 3, episode_number: 7
    )
    assert_includes result.directory.to_s, 'Season 03'
    assert_includes result.generated_filename.to_s, 's03e07'
  end

  test 'tv: pads double-digit season and episode numbers' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 10, episode_number: 12
    )
    assert_includes result.directory.to_s, 'Season 10'
    assert_includes result.generated_filename.to_s, 's10e12'
  end

  test 'tv: media_path includes show dir, season dir, and filename' do
    result = call(
      media_type: 'tv', tmdb_id: 1396, title: 'Breaking Bad', year: 2008, extension: 'mkv',
      season_number: 1, episode_number: 1, episode_title: 'Pilot'
    )
    expected = File.join(@tv_dir, 'Breaking Bad (2008)', 'Season 01',
                         'Breaking Bad (2008) - s01e01 - Pilot.mkv')
    assert_equal expected, result.media_path
  end
end
