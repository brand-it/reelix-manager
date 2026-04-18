# frozen_string_literal: true

require 'test_helper'

class Config
  class VideoTest < ActiveSupport::TestCase
    # ---------------------------------------------------------------------------
    # Shoulda-matchers: presence validations (called inside test blocks)
    # ---------------------------------------------------------------------------
    test 'validates presence of settings_movie_path' do
      assert validate_presence_of(:settings_movie_path).matches?(build(:config_video)),
             'Expected Config::Video to validate presence of settings_movie_path'
    end

    test 'validates presence of settings_tv_path' do
      assert validate_presence_of(:settings_tv_path).matches?(build(:config_video)),
             'Expected Config::Video to validate presence of settings_tv_path'
    end

    test 'validates presence of settings_tmdb_api_key' do
      assert validate_presence_of(:settings_tmdb_api_key).matches?(build(:config_video)),
             'Expected Config::Video to validate presence of settings_tmdb_api_key'
    end

    test 'validates presence of settings_processed_path' do
      assert validate_presence_of(:settings_processed_path).matches?(build(:config_video)),
             'Expected Config::Video to validate presence of settings_processed_path'
    end

    # ---------------------------------------------------------------------------
    # Directory existence — movie_path
    # ---------------------------------------------------------------------------
    test 'is valid when movie_path directory exists' do
      Dir.mktmpdir do |dir|
        config = build(:config_video, movie_dir: dir)
        assert config.valid?, config.errors.full_messages.inspect
      end
    end

    test 'is invalid when movie_path directory does not exist' do
      config = build(:config_video, movie_dir: "/nonexistent/movies/#{SecureRandom.hex}")
      assert_not config.valid?
      assert_includes config.errors[:settings_movie_path], 'does not exist on the filesystem'
    end

    # ---------------------------------------------------------------------------
    # Directory existence — tv_path
    # ---------------------------------------------------------------------------
    test 'is valid when tv_path directory exists' do
      Dir.mktmpdir do |dir|
        config = build(:config_video, tv_dir: dir)
        assert config.valid?, config.errors.full_messages.inspect
      end
    end

    test 'is invalid when tv_path directory does not exist' do
      config = build(:config_video, tv_dir: "/nonexistent/tv/#{SecureRandom.hex}")
      assert_not config.valid?
      assert_includes config.errors[:settings_tv_path], 'does not exist on the filesystem'
    end

    # ---------------------------------------------------------------------------
    # Accessors
    # ---------------------------------------------------------------------------
    test 'settings_movie_path getter returns movie_path setting' do
      config = build(:config_video, movie_dir: '/tmp')
      assert_equal '/tmp', config.settings_movie_path
    end

    test 'settings_tv_path getter returns tv_path setting' do
      config = build(:config_video, tv_dir: '/tmp')
      assert_equal '/tmp', config.settings_tv_path
    end

    test 'settings_tmdb_api_key getter returns tmdb_api_key setting' do
      config = build(:config_video)
      assert_equal 'test_key_123', config.settings_tmdb_api_key
    end

    test 'settings_processed_path getter returns processed_path setting' do
      config = build(:config_video)
      assert_equal '/tmp', config.settings_processed_path
    end

    # ---------------------------------------------------------------------------
    # Persistence
    # ---------------------------------------------------------------------------
    test 'saves and reloads all settings correctly' do
      config = create(:config_video)
      config.reload
      assert_equal '/tmp', config.settings_movie_path
      assert_equal '/tmp', config.settings_tv_path
      assert_equal 'test_key_123', config.settings_tmdb_api_key
      assert_equal '/tmp', config.settings_processed_path
    end
  end
end
