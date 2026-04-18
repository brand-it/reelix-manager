# frozen_string_literal: true

require 'test_helper'

class VideoBlobTest < ActiveSupport::TestCase
  setup do
    @movie_dir = Dir.mktmpdir('video_blob_model_movie_paths')
    @tv_dir = Dir.mktmpdir('video_blob_model_tv_paths')
    create(:config_video, movie_dir: @movie_dir, tv_dir: @tv_dir)
  end

  teardown do
    FileUtils.rm_rf(@movie_dir)
    FileUtils.rm_rf(@tv_dir)
    Config::Video.delete_all
  end

  test 'is valid with required attributes' do
    blob = build(:video_blob)
    assert blob.valid?, blob.errors.full_messages.inspect
  end

  test 'requires key' do
    blob = build(:video_blob, key: nil)
    assert_not blob.valid?
    assert_includes blob.errors[:key], "can't be blank"
  end

  test 'requires filename' do
    blob = build(:video_blob, filename: nil)
    assert_not blob.valid?
    assert_includes blob.errors[:filename], "can't be blank"
  end

  test 'requires unique key' do
    create(:video_blob, key: '/movies/Dup (2020)/Dup (2020).mkv')
    blob = build(:video_blob, key: '/movies/Dup (2020)/Dup (2020).mkv')
    assert_not blob.valid?
    assert_includes blob.errors[:key], 'has already been taken'
  end

  test 'media_type enum includes movie and tv' do
    assert_equal 0, VideoBlob.media_types[:movie]
    assert_equal 1, VideoBlob.media_types[:tv]
  end

  test 'movie? returns true for movie media type' do
    blob = build(:video_blob, media_type: :movie)
    assert blob.movie?
  end

  test 'tv? returns true for tv media type' do
    blob = build(:video_blob, :tv)
    assert blob.tv?
  end

  test 'generated_filename builds sanitized tv filename with episode title' do
    blob = build(:video_blob, :tv,
                 title: 'Law/Order\\..', year: 2008,
                 season_number: 1, episode_number: 2)
    blob.path_extension = 'MKV'
    blob.episode_title = "Pilot/Part\\.. \x00"
    filename = blob.generated_filename
    assert_equal 'Law-Order-. (2008) - s01e02 - Pilot-Part-..mkv', filename
  end

  test 'generated_filename builds movie filename from unsaved blob' do
    blob = build(:video_blob, title: 'Batman Begins', year: 2005, media_type: :movie)
    blob.path_extension = '.MKV'

    assert_equal 'Batman Begins (2005).mkv', blob.generated_filename
  end

  test 'extra_type enum includes all EXTRA_TYPES keys' do
    VideoBlob::EXTRA_TYPES.each_key do |key|
      assert VideoBlob.extra_types.key?(key.to_s), "Missing extra_type: #{key}"
    end
  end

  test 'without_tmdb_id scope returns blobs with nil tmdb_id' do
    with    = create(:video_blob, :with_tmdb_id)
    without = create(:video_blob)
    ids = VideoBlob.without_tmdb_id.pluck(:id)
    assert_includes ids, without.id
    assert_not_includes ids, with.id
  end

  test 'movies scope returns only movies' do
    movie = create(:video_blob, media_type: :movie)
    tv    = create(:video_blob, :tv)
    ids = VideoBlob.movies.pluck(:id)
    assert_includes ids, movie.id
    assert_not_includes ids, tv.id
  end

  test 'tv_shows scope returns only tv blobs' do
    movie = create(:video_blob, media_type: :movie)
    tv    = create(:video_blob, :tv)
    ids = VideoBlob.tv_shows.pluck(:id)
    assert_includes ids, tv.id
    assert_not_includes ids, movie.id
  end

  # ---------------------------------------------------------------------------
  # media_name
  # ---------------------------------------------------------------------------

  test 'media_name returns canonical name for movie' do
    blob = build(:video_blob, title: 'Batman Begins', year: 2005, tmdb_id: 272, media_type: :movie)
    assert_equal 'Batman Begins (2005)', blob.media_name
  end

  test 'media_name returns canonical name for tv episode' do
    blob = build(:video_blob, :tv,
                 title: 'Breaking Bad', year: 2008, tmdb_id: 1396,
                 season_number: 1, episode_number: 1)
    assert_equal 'Breaking Bad (2008) - s01e01', blob.media_name
  end

  test 'media_name zero-pads season and episode numbers' do
    blob = build(:video_blob, :tv,
                 title: 'My Show', year: 2020, tmdb_id: 99,
                 season_number: 3, episode_number: 7)
    assert_equal 'My Show (2020) - s03e07', blob.media_name
  end

  test 'media_name omits year when nil' do
    blob = build(:video_blob, title: 'Timeless', year: nil, tmdb_id: 42, media_type: :movie)
    assert_equal 'Timeless', blob.media_name
  end

  test 'media_name returns nil when title is missing' do
    blob = build(:video_blob, title: nil, year: 2020, tmdb_id: 1, media_type: :movie)
    assert_nil blob.media_name
  end

  test 'media_name does not depend on tmdb_id' do
    blob = build(:video_blob, title: 'Some Movie', year: 2020, tmdb_id: nil, media_type: :movie)
    assert_equal 'Some Movie (2020)', blob.media_name
  end

  test 'media_name returns nil for tv when season_number is missing' do
    blob = build(:video_blob, :tv,
                 title: 'My Show', year: 2020, tmdb_id: 99,
                 season_number: nil, episode_number: 1)
    assert_nil blob.media_name
  end

  test 'media_name returns nil for tv when episode_number is missing' do
    blob = build(:video_blob, :tv,
                 title: 'My Show', year: 2020, tmdb_id: 99,
                 season_number: 1, episode_number: nil)
    assert_nil blob.media_name
  end

  # ---------------------------------------------------------------------------
  # media_path
  # ---------------------------------------------------------------------------

  test 'media_path returns absolute path for movie' do
    blob = build(:video_blob,
                 title: 'Batman Begins', year: 2005, tmdb_id: 272,
                 media_type: :movie,
                 filename: 'Batman Begins (2005).mkv')
    expected = File.join(@movie_dir, 'Batman Begins (2005)', 'Batman Begins (2005).mkv')
    assert_equal expected, blob.media_path
  end

  test 'media_path returns absolute path for tv episode' do
    blob = build(:video_blob, :tv,
                 title: 'Breaking Bad', year: 2008, tmdb_id: 1396,
                 season_number: 1, episode_number: 1,
                 filename: 'Breaking Bad (2008) - s01e01 - Pilot.mkv')
    expected = File.join(@tv_dir, 'Breaking Bad (2008)', 'Season 01',
                         'Breaking Bad (2008) - s01e01 - Pilot.mkv')
    assert_equal expected, blob.media_path
  end

  test 'media_path uses sanitized title formatting' do
    blob = build(:video_blob,
                 title: "  Batman/Begins\\.. \x00  ",
                 year: 2005,
                 tmdb_id: 272,
                 media_type: :movie,
                 filename: 'Batman-Begins-. (2005).mkv')

    expected = File.join(@movie_dir, 'Batman-Begins-. (2005)', 'Batman-Begins-. (2005).mkv')
    assert_equal expected, blob.media_path
  end

  test 'media_path falls back to generated filename for unsaved blob' do
    blob = build(:video_blob, :tv,
                 title: 'Breaking Bad', year: 2008,
                 season_number: 1, episode_number: 1,
                 filename: nil)
    blob.path_extension = 'mkv'
    blob.episode_title = 'Pilot'

    expected = File.join(@tv_dir, 'Breaking Bad (2008)', 'Season 01',
                         'Breaking Bad (2008) - s01e01 - Pilot.mkv')
    assert_equal expected, blob.media_path
  end

  test 'media_path returns nil when media_name is nil' do
    blob = build(:video_blob, title: nil, year: 2020, tmdb_id: nil, media_type: :movie)
    assert_nil blob.media_path
  end
end
