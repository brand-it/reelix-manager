# frozen_string_literal: true

require 'test_helper'

module Sources
  class VideoBlobsTest < ActiveSupport::TestCase
    # -- Tests -----------------------------------------------------------------

    test 'returns video blobs grouped by [media_type, tmdb_id]' do
      source  = Sources::VideoBlobs.new
      results = source.fetch([['movie', video_blobs(:inception).tmdb_id]])

      assert_equal 1, results.size
      assert_equal 1, results.first.size
      assert_equal video_blobs(:inception).filename, results.first.first.filename
    end

    test 'returns empty array for a key with no matching blobs' do
      source  = Sources::VideoBlobs.new
      results = source.fetch([['movie', 0]])

      assert_equal 1, results.size
      assert_empty results.first
    end

    test 'batches multiple keys in a single fetch' do
      create(:video_blob, :with_tmdb_id, tmdb_id: 11_111, media_type: :movie)
      create(:video_blob, :with_tmdb_id, tmdb_id: 22_222, media_type: :movie)

      source  = Sources::VideoBlobs.new
      keys    = [['movie', 11_111], ['movie', 22_222]]

      query_count = count_sql_queries do
        results = source.fetch(keys)
        assert_equal 1, results[0].size
        assert_equal 1, results[1].size
      end

      assert_equal 1, query_count, 'expected exactly one SQL query for both keys'
    end

    test 'returns blobs only for the requested media_type and tmdb_id' do
      tmdb_id = 55_555
      create(:video_blob, :tv, :with_tmdb_id, tmdb_id: tmdb_id)
      create(:video_blob, :with_tmdb_id, tmdb_id: tmdb_id, media_type: :movie)

      source = Sources::VideoBlobs.new

      movie_results = source.fetch([['movie', tmdb_id]]).first
      tv_results    = source.fetch([['tv',    tmdb_id]]).first

      assert(movie_results.all? { |b| b.media_type == 'movie' })
      assert(tv_results.all? { |b| b.media_type == 'tv' })
    end

    test 'returns multiple blobs for the same key (e.g. editions)' do
      tmdb_id = 66_666
      create(:video_blob, :with_tmdb_id, tmdb_id: tmdb_id, edition: 'Theatrical')
      create(:video_blob, :with_tmdb_id, tmdb_id: tmdb_id, edition: "Director's Cut",
                                         key: "/movies/Film (2000)/Film (2000) - Director's Cut.mkv",
                                         filename: "Film (2000) - Director's Cut.mkv")

      source  = Sources::VideoBlobs.new
      results = source.fetch([['movie', tmdb_id]])

      assert_equal 2, results.first.size
    end
  end
end
