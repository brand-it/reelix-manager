# frozen_string_literal: true

require 'test_helper'

class Config
  class VideosControllerTest < ActionDispatch::IntegrationTest
    setup do
      Config::Video.delete_all
      sign_in create(:user)
    end

    # ---------------------------------------------------------------------------
    # GET new
    # ---------------------------------------------------------------------------
    test 'GET new returns 200' do
      get new_config_video_path
      assert_response :success
    end

    # ---------------------------------------------------------------------------
    # POST create
    # ---------------------------------------------------------------------------
    test 'POST create with valid params redirects to edit' do
      assert_difference('Config::Video.count', 1) do
        post config_video_path, params: {
          config_video: {
            settings_movie_path: '/tmp',
            settings_tv_path: '/tmp',
            settings_tmdb_api_key: 'mykey',
            settings_processed_path: '/tmp'
          }
        }
      end
      assert_redirected_to edit_config_video_path
    end

    test 'POST create with missing paths renders new with 422' do
      post config_video_path, params: {
        config_video: {
          settings_movie_path: '',
          settings_tv_path: '',
          settings_tmdb_api_key: '',
          settings_processed_path: ''
        }
      }
      assert_response :unprocessable_entity
    end

    test 'POST create with non-existent movie_path renders new with 422' do
      post config_video_path, params: {
        config_video: {
          settings_movie_path: '/nonexistent/movies',
          settings_tv_path: '/tmp',
          settings_tmdb_api_key: 'mykey',
          settings_processed_path: '/tmp'
        }
      }
      assert_response :unprocessable_entity
    end

    test 'POST create with non-existent tv_path renders new with 422' do
      post config_video_path, params: {
        config_video: {
          settings_movie_path: '/tmp',
          settings_tv_path: '/nonexistent/tv',
          settings_tmdb_api_key: 'mykey',
          settings_processed_path: '/tmp'
        }
      }
      assert_response :unprocessable_entity
    end

    # ---------------------------------------------------------------------------
    # GET edit
    # ---------------------------------------------------------------------------
    test 'GET edit with existing config returns 200' do
      create(:config_video)
      get edit_config_video_path
      assert_response :success
    end

    test 'GET edit without existing config redirects to new' do
      get edit_config_video_path
      assert_redirected_to new_config_video_path
    end

    # ---------------------------------------------------------------------------
    # PATCH update
    # ---------------------------------------------------------------------------
    test 'PATCH update with valid params redirects to edit' do
      create(:config_video)
      patch config_video_path, params: {
        config_video: {
          settings_movie_path: '/tmp',
          settings_tv_path: '/tmp',
          settings_tmdb_api_key: 'new_key',
          settings_processed_path: '/tmp'
        }
      }
      assert_redirected_to edit_config_video_path
    end

    test 'PATCH update with missing params renders edit with 422' do
      create(:config_video)
      patch config_video_path, params: {
        config_video: {
          settings_movie_path: '',
          settings_tv_path: '',
          settings_tmdb_api_key: '',
          settings_processed_path: ''
        }
      }
      assert_response :unprocessable_entity
    end

    test 'PATCH update with non-existent movie_path renders edit with 422' do
      create(:config_video)
      patch config_video_path, params: {
        config_video: {
          settings_movie_path: '/nonexistent/movies',
          settings_tv_path: '/tmp',
          settings_tmdb_api_key: 'key',
          settings_processed_path: '/tmp'
        }
      }
      assert_response :unprocessable_entity
    end

    test 'PATCH update with non-existent tv_path renders edit with 422' do
      create(:config_video)
      patch config_video_path, params: {
        config_video: {
          settings_movie_path: '/tmp',
          settings_tv_path: '/nonexistent/tv',
          settings_tmdb_api_key: 'key',
          settings_processed_path: '/tmp'
        }
      }
      assert_response :unprocessable_entity
    end

    test 'PATCH update without existing config redirects to new' do
      patch config_video_path, params: {
        config_video: {
          settings_movie_path: '/tmp',
          settings_tv_path: '/tmp',
          settings_tmdb_api_key: 'key',
          settings_processed_path: '/tmp'
        }
      }
      assert_redirected_to new_config_video_path
    end
  end
end
