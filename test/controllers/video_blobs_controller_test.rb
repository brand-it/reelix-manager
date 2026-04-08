# frozen_string_literal: true

require "test_helper"

class VideoBlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in create(:user)
  end

  # ---------------------------------------------------------------------------
  # GET index — renders
  # ---------------------------------------------------------------------------
  test "GET index returns 200" do
    get video_blobs_path
    assert_response :success
  end

  test "GET index shows empty state when no blobs" do
    VideoBlob.delete_all
    get video_blobs_path
    assert_response :success
    assert_select "turbo-frame#blobs_grid"
    assert_select "p.fs-5", /No blobs found/
  end

  test "GET index shows blob cards" do
    blob = create(:video_blob, title: "Inception", year: 2010)
    get video_blobs_path
    assert_response :success
    assert_select "p.card-title", /#{blob.title}/
  end

  # ---------------------------------------------------------------------------
  # Search
  # ---------------------------------------------------------------------------
  test "GET index with q param filters by title" do
    create(:video_blob, title: "Inception", year: 2010)
    create(:video_blob, title: "Avatar",    year: 2009)
    get video_blobs_path, params: { q: "Inception" }
    assert_response :success
    assert_select "p.card-title", /Inception/
    assert_select "p.card-title", count: 0, text: /Avatar/
  end

  test "GET index with q param that matches nothing shows empty state" do
    VideoBlob.delete_all
    get video_blobs_path, params: { q: "xyznotfound" }
    assert_response :success
    assert_select "p.fs-5", /No blobs found/
    assert_select "p.fs-5", /xyznotfound/
  end

  # ---------------------------------------------------------------------------
  # Media-type filter
  # ---------------------------------------------------------------------------
  test "GET index filtered to movies shows only movie blobs" do
    create(:video_blob,       title: "Inception", year: 2010)
    create(:video_blob, :tv,  title: "Breaking Bad")
    get video_blobs_path, params: { media_type: "movie" }
    assert_response :success
    assert_select "p.card-title", /Inception/
    assert_select "p.card-title", count: 0, text: /Breaking Bad/
  end

  test "GET index filtered to tv shows only tv blobs" do
    create(:video_blob,       title: "Inception",    year: 2010)
    create(:video_blob, :tv,  title: "Breaking Bad")
    get video_blobs_path, params: { media_type: "tv" }
    assert_response :success
    assert_select "p.card-title", /Breaking Bad/
    assert_select "p.card-title", count: 0, text: /Inception/
  end

  test "GET index with invalid media_type shows all blobs" do
    create(:video_blob,      title: "Inception",    year: 2010)
    create(:video_blob, :tv, title: "Breaking Bad")
    get video_blobs_path, params: { media_type: "invalid" }
    assert_response :success
    assert_select "p.card-title", /Inception/
    assert_select "p.card-title", /Breaking Bad/
  end

  # ---------------------------------------------------------------------------
  # Poster image
  # ---------------------------------------------------------------------------
  test "GET index shows poster img when poster_url is present" do
    create(:video_blob, title: "Inception", poster_url: "https://image.tmdb.org/t/p/w342/abc.jpg")
    get video_blobs_path
    assert_response :success
    assert_select "img.card-img-top[src='https://image.tmdb.org/t/p/w342/abc.jpg']"
  end

  test "GET index shows filename placeholder when poster_url is blank" do
    blob = create(:video_blob, title: "Inception", poster_url: nil)
    get video_blobs_path
    assert_response :success
    assert_select "div.card-img-top", text: /#{Regexp.escape(blob.filename)}/
  end

  # ---------------------------------------------------------------------------
  # TV season/episode display
  # ---------------------------------------------------------------------------
  test "GET index shows season and episode for TV blobs" do
    create(:video_blob, :tv, title: "Breaking Bad", season_number: 3, episode_number: 7)
    get video_blobs_path
    assert_response :success
    assert_select "p.card-text", /S03E07/
  end
end
