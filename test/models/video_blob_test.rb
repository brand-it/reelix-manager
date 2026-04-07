# frozen_string_literal: true

require "test_helper"

class VideoBlobTest < ActiveSupport::TestCase
  test "is valid with required attributes" do
    blob = build(:video_blob)
    assert blob.valid?, blob.errors.full_messages.inspect
  end

  test "requires key" do
    blob = build(:video_blob, key: nil)
    assert_not blob.valid?
    assert_includes blob.errors[:key], "can't be blank"
  end

  test "requires filename" do
    blob = build(:video_blob, filename: nil)
    assert_not blob.valid?
    assert_includes blob.errors[:filename], "can't be blank"
  end

  test "requires unique key" do
    create(:video_blob, key: "/movies/Dup (2020)/Dup (2020).mkv")
    blob = build(:video_blob, key: "/movies/Dup (2020)/Dup (2020).mkv")
    assert_not blob.valid?
    assert_includes blob.errors[:key], "has already been taken"
  end

  test "media_type enum includes movie and tv" do
    assert_equal 0, VideoBlob.media_types[:movie]
    assert_equal 1, VideoBlob.media_types[:tv]
  end

  test "movie? returns true for movie media type" do
    blob = build(:video_blob, media_type: :movie)
    assert blob.movie?
  end

  test "tv? returns true for tv media type" do
    blob = build(:video_blob, :tv)
    assert blob.tv?
  end

  test "extra_type enum includes all EXTRA_TYPES keys" do
    VideoBlob::EXTRA_TYPES.each_key do |key|
      assert VideoBlob.extra_types.key?(key.to_s), "Missing extra_type: #{key}"
    end
  end

  test "without_tmdb_id scope returns blobs with nil tmdb_id" do
    with    = create(:video_blob, :with_tmdb_id)
    without = create(:video_blob)
    ids = VideoBlob.without_tmdb_id.pluck(:id)
    assert_includes ids, without.id
    assert_not_includes ids, with.id
  end

  test "movies scope returns only movies" do
    movie = create(:video_blob, media_type: :movie)
    tv    = create(:video_blob, :tv)
    ids = VideoBlob.movies.pluck(:id)
    assert_includes ids, movie.id
    assert_not_includes ids, tv.id
  end

  test "tv_shows scope returns only tv blobs" do
    movie = create(:video_blob, media_type: :movie)
    tv    = create(:video_blob, :tv)
    ids = VideoBlob.tv_shows.pluck(:id)
    assert_includes ids, tv.id
    assert_not_includes ids, movie.id
  end
end
