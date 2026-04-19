# frozen_string_literal: true

require 'test_helper'

class VideoBlobTmdbSyncJobTest < ActiveSupport::TestCase
  test 'delegates to VideoBlobs::TmdbSyncService' do
    blob = create(:video_blob, tmdb_id: 27_205)
    called_with = nil
    original = VideoBlobs::TmdbSyncService.method(:call)
    VideoBlobs::TmdbSyncService.define_singleton_method(:call) { |record| called_with = record }

    VideoBlobTmdbSyncJob.perform_now(blob.id)

    assert_equal blob, called_with
  ensure
    VideoBlobs::TmdbSyncService.define_singleton_method(:call, &original)
  end

  test 'skips blob without tmdb_id' do
    blob = create(:video_blob, tmdb_id: nil)
    called = false
    original = VideoBlobs::TmdbSyncService.method(:call)
    VideoBlobs::TmdbSyncService.define_singleton_method(:call) { |_| called = true }

    VideoBlobTmdbSyncJob.perform_now(blob.id)

    assert_not called
  ensure
    VideoBlobs::TmdbSyncService.define_singleton_method(:call, &original)
  end

  test 'skips gracefully when blob no longer exists' do
    assert_nothing_raised { VideoBlobTmdbSyncJob.perform_now(0) }
  end
end
