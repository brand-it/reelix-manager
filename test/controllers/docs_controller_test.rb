# frozen_string_literal: true

require 'test_helper'

class DocsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @oauth_app = Doorkeeper::Application.find_or_create_by!(name: 'Reelix') do |a|
      a.uid           = 'reelix-client'
      a.redirect_uri  = ''
      a.scopes        = ''
      a.confidential  = false
    end
  end

  test 'GET /docs/api is publicly accessible without authentication' do
    get '/docs/api'
    assert_response :success
    assert_select 'h1', text: /API Documentation/i
  end

  test 'GET /docs/api shows device flow steps' do
    get '/docs/api'
    assert_response :success
    assert_match @oauth_app.uid, response.body
    assert_match '/oauth/authorize_device', response.body
    assert_match '/oauth/token', response.body
  end

  test 'GET /docs/api lists registered client applications' do
    get '/docs/api'
    assert_response :success
    assert_match @oauth_app.name, response.body
    assert_match @oauth_app.uid, response.body
  end
end
