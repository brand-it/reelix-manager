# frozen_string_literal: true

require 'test_helper'

class VideoBlobsTmdbSyncServiceTest < ActiveSupport::TestCase
  test 'syncs movie metadata from tmdb_id' do
    blob = create(:video_blob, tmdb_id: 27_205, title: 'Old', year: 1999, poster_url: nil)
    stub = Object.new.tap do |client|
      client.define_singleton_method(:results) do
        {
          'title' => 'Inception',
          'release_date' => '2010-07-16',
          'poster_path' => '/inception.jpg'
        }
      end
    end

    TheMovieDb::Movie.define_singleton_method(:new) { |**| stub }
    VideoBlobs::TmdbSyncService.call(blob)

    blob.reload
    assert_equal 'Inception', blob.title
    assert_equal 2010, blob.year
    assert_equal 'https://image.tmdb.org/t/p/w500/inception.jpg', blob.poster_url
  ensure
    TheMovieDb::Movie.singleton_class.remove_method(:new)
  end

  test 'syncs tv metadata from tmdb_id' do
    blob = create(:video_blob, :tv, tmdb_id: 1396, title: 'Old Show', year: 2000, poster_url: nil)
    stub = Object.new.tap do |client|
      client.define_singleton_method(:results) do
        {
          'name' => 'Breaking Bad',
          'first_air_date' => '2008-01-20',
          'poster_path' => '/breaking-bad.jpg'
        }
      end
    end

    TheMovieDb::Tv.define_singleton_method(:new) { |**| stub }
    VideoBlobs::TmdbSyncService.call(blob)

    blob.reload
    assert_equal 'Breaking Bad', blob.title
    assert_equal 2008, blob.year
    assert_equal 'https://image.tmdb.org/t/p/w500/breaking-bad.jpg', blob.poster_url
  ensure
    TheMovieDb::Tv.singleton_class.remove_method(:new)
  end
end
