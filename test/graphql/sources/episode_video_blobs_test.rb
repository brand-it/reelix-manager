# frozen_string_literal: true

require 'test_helper'

module Sources
  class EpisodeVideoBlobsTest < ActiveSupport::TestCase
    # -- Tests -----------------------------------------------------------------

    test 'returns video blobs for a matching episode' do
      blob   = video_blobs(:breaking_bad_s01e01)
      source = Sources::EpisodeVideoBlobs.new
      key    = [blob.tmdb_id, blob.season_number, blob.episode_number]

      results = source.fetch([key])

      assert_equal 1, results.size
      assert_equal 1, results.first.size
      assert_equal blob.filename, results.first.first.filename
    end

    test 'returns empty array for an episode with no matching blob' do
      source = Sources::EpisodeVideoBlobs.new
      results = source.fetch([[1396, 1, 99]])

      assert_equal 1, results.size
      assert_empty results.first
    end

    test 'batches multiple episodes for the same show in one query' do
      tmdb_id = 77_777
      ep1 = create(:video_blob, :tv, :with_tmdb_id, tmdb_id: tmdb_id, season_number: 1, episode_number: 1)
      ep2 = create(:video_blob, :tv, :with_tmdb_id, tmdb_id: tmdb_id, season_number: 1, episode_number: 2,
                                                    key: "/tv/Show #{tmdb_id}/Season 01/Show - S01E02.mkv",
                                                    filename: 'Show - S01E02.mkv')

      source = Sources::EpisodeVideoBlobs.new
      keys   = [
        [tmdb_id, ep1.season_number, ep1.episode_number],
        [tmdb_id, ep2.season_number, ep2.episode_number]
      ]

      query_count = count_sql_queries do
        results = source.fetch(keys)
        assert_equal 1, results[0].size
        assert_equal 1, results[1].size
      end

      assert_equal 1, query_count, 'expected exactly one SQL query for both episode keys'
    end

    test 'batches episodes across multiple shows in one query' do
      show_a = 88_888
      show_b = 99_999
      create(:video_blob, :tv, :with_tmdb_id, tmdb_id: show_a, season_number: 1, episode_number: 1)
      create(:video_blob, :tv, :with_tmdb_id, tmdb_id: show_b, season_number: 2, episode_number: 3,
                                              key: "/tv/Show #{show_b}/Season 02/Show - S02E03.mkv",
                                              filename: 'Show - S02E03.mkv')

      source = Sources::EpisodeVideoBlobs.new
      keys   = [[show_a, 1, 1], [show_b, 2, 3]]

      query_count = count_sql_queries do
        results = source.fetch(keys)
        assert_equal 1, results[0].size
        assert_equal 1, results[1].size
      end

      assert_equal 1, query_count, 'expected one SQL query for episodes across two shows'
    end

    test 'does not cross-contaminate results between episodes' do
      tmdb_id = 44_444
      create(:video_blob, :tv, :with_tmdb_id, tmdb_id: tmdb_id, season_number: 1, episode_number: 1)
      create(:video_blob, :tv, :with_tmdb_id, tmdb_id: tmdb_id, season_number: 1, episode_number: 2,
                                              key: '/tv/Show/Season 01/Show - S01E02.mkv',
                                              filename: 'Show - S01E02.mkv')

      source  = Sources::EpisodeVideoBlobs.new
      results = source.fetch([[tmdb_id, 1, 1], [tmdb_id, 1, 2]])

      assert(results[0].all? { |b| b.episode_number == 1 })
      assert(results[1].all? { |b| b.episode_number == 2 })
    end
  end
end
