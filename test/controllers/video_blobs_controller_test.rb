require "test_helper"

class VideoBlobsControllerTest < ActionDispatch::IntegrationTest
  setup do
    sign_in users(:regular)
  end

  test "GET index renders library page" do
    get video_blobs_path

    assert_response :success
    assert_select "h1", text: "Library"
    assert_select "#library_results"
  end

  test "GET index filters results with turbo stream" do
    get video_blobs_path,
        params: { q: "Breaking", media_type: "tv" },
        headers: { "Accept" => Mime[:turbo_stream].to_s }

    assert_response :success
    assert_equal Mime[:turbo_stream].to_s, response.media_type
    assert_includes response.body, %(target="library_blob_count")
    assert_includes response.body, %(target="library_results")
    assert_includes response.body, %(id="library_blob_count")
    assert_includes response.body, %(id="library_results")
    assert_includes response.body, "Breaking Bad"
    refute_includes response.body, "Inception"
  end
end
