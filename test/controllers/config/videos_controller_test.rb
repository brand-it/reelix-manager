require "test_helper"

class Config::VideosControllerTest < ActionDispatch::IntegrationTest
  test "GET new returns 200" do
    get new_config_video_path
    assert_response :success
  end

  test "POST create with valid params redirects to edit" do
    assert_difference("Config::Video.count", 1) do
      post config_video_path, params: {
        config_video: {
          settings_upload_path: "/uploads",
          settings_tmdb_api_key: "mykey",
          settings_processed_path: "/processed"
        }
      }
    end
    assert_redirected_to edit_config_video_path
  end

  test "POST create with invalid params renders new" do
    post config_video_path, params: {
      config_video: {
        settings_upload_path: "",
        settings_tmdb_api_key: "",
        settings_processed_path: ""
      }
    }
    assert_response :unprocessable_entity
  end

  test "GET edit with existing config returns 200" do
    configs(:video_config)
    get edit_config_video_path
    assert_response :success
  end

  test "GET edit without existing config redirects to new" do
    Config::Video.delete_all
    get edit_config_video_path
    assert_redirected_to new_config_video_path
  end

  test "PATCH update with valid params redirects to edit" do
    configs(:video_config)
    patch config_video_path, params: {
      config_video: {
        settings_upload_path: "/new_uploads",
        settings_tmdb_api_key: "new_key",
        settings_processed_path: "/new_processed"
      }
    }
    assert_redirected_to edit_config_video_path
  end

  test "PATCH update with invalid params renders edit" do
    configs(:video_config)
    patch config_video_path, params: {
      config_video: {
        settings_upload_path: "",
        settings_tmdb_api_key: "",
        settings_processed_path: ""
      }
    }
    assert_response :unprocessable_entity
  end
end
