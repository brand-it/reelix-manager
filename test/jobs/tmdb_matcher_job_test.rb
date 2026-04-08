# frozen_string_literal: true

require "test_helper"

class TmdbMatcherJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  test "delegates to TmdbMatcherService" do
    blob = create(:video_blob, title: "Inception", year: 2010)
    called_with = nil
    TmdbMatcherService.define_singleton_method(:call) { |b| called_with = b }

    TmdbMatcherJob.perform_now(blob.id)

    assert_equal blob, called_with
  ensure
    TmdbMatcherService.singleton_class.remove_method(:call)
  end

  test "skips blob that already has a tmdb_id" do
    blob = create(:video_blob, :with_tmdb_id)
    original_id = blob.tmdb_id
    called = false
    TmdbMatcherService.define_singleton_method(:call) { |_| called = true }

    TmdbMatcherJob.perform_now(blob.id)

    assert_not called
    assert_equal original_id, blob.reload.tmdb_id
  ensure
    TmdbMatcherService.singleton_class.remove_method(:call)
  end

  test "skips gracefully when blob no longer exists" do
    assert_nothing_raised { TmdbMatcherJob.perform_now(0) }
  end
end
