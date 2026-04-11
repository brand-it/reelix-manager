# frozen_string_literal: true

require "test_helper"

class VideoBlobsUpsertFromUploadServiceTest < ActiveSupport::TestCase
  def build_blob(media_type:, tmdb_id:, title:, year:, extension:, season_number: nil, episode_number: nil, episode_title: nil)
    VideoBlob.new(
      media_type:,
      tmdb_id:,
      title:,
      year:,
      path_extension: extension,
      episode_title:,
      season_number:,
      episode_number:
    )
  end

  test "creates a blob from finalized upload data" do
    video_blob = build_blob(
      media_type: "movie",
      tmdb_id: 272,
      title: "Batman Begins",
      year: 2005,
      extension: "mkv"
    )
    video_blob.filename = "Batman Begins (2005).mkv"
    video_blob.key = "/movies/Batman Begins (2005)/Batman Begins (2005).mkv"

    blob = VideoBlobs::UpsertFromUploadService.call(
      video_blob: video_blob
    )

    assert_predicate blob, :persisted?
    assert_equal video_blob.key, blob.key
    assert_equal video_blob.filename, blob.filename
    assert_equal "Batman Begins", blob.title
    assert_equal 2005, blob.year
    assert_equal 272, blob.tmdb_id
    assert_equal "mkv", blob.path_extension
    assert_nil blob.episode_title
    assert_equal "video/x-matroska", blob.content_type
  end

  test "updates an existing blob for the same final path" do
    existing = create(:video_blob, key: "/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - s01e01 - Pilot.mkv", filename: "old.mkv", title: "Old Title")
    video_blob = build_blob(
      media_type: "tv",
      tmdb_id: 1396,
      title: "Breaking Bad",
      year: 2008,
      extension: "mkv",
      episode_title: "Pilot",
      season_number: 1,
      episode_number: 1
    )
    video_blob.filename = "Breaking Bad (2008) - s01e01 - Pilot.mkv"
    video_blob.key = "/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - s01e01 - Pilot.mkv"

    blob = VideoBlobs::UpsertFromUploadService.call(
      video_blob: video_blob
    )

    assert_equal existing.id, blob.id
    assert_equal video_blob.filename, blob.filename
    assert_equal "Breaking Bad", blob.title
    assert_equal 2008, blob.year
    assert_equal 1396, blob.tmdb_id
    assert_equal "mkv", blob.path_extension
    assert_equal "Pilot", blob.episode_title
    assert_equal 1, blob.season_number
    assert_equal 1, blob.episode_number
  end
end
