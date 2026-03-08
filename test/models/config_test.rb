require "test_helper"

class ConfigTest < ActiveSupport::TestCase
  test "newest returns a new instance when no records exist" do
    Config::Video.delete_all
    result = Config::Video.newest
    assert_not result.persisted?
  end

  test "newest returns the most recently updated record" do
    config = configs(:video_config)
    result = Config::Video.newest
    assert result.persisted?
    assert_equal config.id, result.id
  end

  test "settings= merges new values with existing settings" do
    config = Config::Video.new
    config.settings = { upload_path: "/uploads" }
    config.settings = { tmdb_api_key: "key123" }
    assert_equal "/uploads", config.settings_upload_path
    assert_equal "key123", config.settings_tmdb_api_key
  end
end
