require "test_helper"

class Config::VideoTest < ActiveSupport::TestCase
  test "is invalid without upload_path" do
    config = Config::Video.new
    config.settings = { tmdb_api_key: "key", processed_path: "/proc" }
    assert_not config.valid?
    assert_includes config.errors[:settings_upload_path], "can't be blank"
  end

  test "is invalid without tmdb_api_key" do
    config = Config::Video.new
    config.settings = { upload_path: "/uploads", processed_path: "/proc" }
    assert_not config.valid?
    assert_includes config.errors[:settings_tmdb_api_key], "can't be blank"
  end

  test "is invalid without processed_path" do
    config = Config::Video.new
    config.settings = { upload_path: "/uploads", tmdb_api_key: "key" }
    assert_not config.valid?
    assert_includes config.errors[:settings_processed_path], "can't be blank"
  end

  test "is valid with all required settings" do
    config = Config::Video.new
    config.settings = { upload_path: "/uploads", tmdb_api_key: "key", processed_path: "/proc" }
    assert config.valid?
  end

  test "settings_upload_path getter returns upload_path setting" do
    config = Config::Video.new
    config.settings = { upload_path: "/my/path" }
    assert_equal "/my/path", config.settings_upload_path
  end

  test "settings_tmdb_api_key getter returns tmdb_api_key setting" do
    config = Config::Video.new
    config.settings = { tmdb_api_key: "abc123" }
    assert_equal "abc123", config.settings_tmdb_api_key
  end

  test "settings_processed_path getter returns processed_path setting" do
    config = Config::Video.new
    config.settings = { processed_path: "/out" }
    assert_equal "/out", config.settings_processed_path
  end

  test "fixture loads correctly" do
    config = configs(:video_config)
    assert_equal "Config::Video", config.type
    assert_equal "/tmp/uploads", config.settings_upload_path
    assert_equal "test_key_123", config.settings_tmdb_api_key
    assert_equal "/tmp/processed", config.settings_processed_path
  end
end
