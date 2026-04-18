# frozen_string_literal: true

require 'test_helper'

# Tests the full OAuth 2.0 Device Authorization Grant (RFC 8628) flow:
#
#   Step 1  — Device POSTs to /oauth/authorize_device → receives device_code + user_code
#   Step 2  — Authenticated user visits /oauth/device and approves with the user_code
#   Step 3  — Device polls POST /oauth/token → authorization_pending → access_token
#
class DeviceAuthorizationFlowTest < ActionDispatch::IntegrationTest
  DEVICE_GRANT_TYPE = 'urn:ietf:params:oauth:grant-type:device_code'

  setup do
    @user = create(:user)
    @oauth_app = Doorkeeper::Application.create!(
      name: 'Test Device App',
      uid: "device-client-#{SecureRandom.hex(4)}",
      redirect_uri: '',
      scopes: 'search upload',
      confidential: false
    )
  end

  teardown do
    Doorkeeper::AccessToken
      .where(application_id: @oauth_app.id)
      .or(Doorkeeper::AccessToken.where(resource_owner_id: @user.id))
      .delete_all
    Doorkeeper::DeviceAuthorizationGrant::DeviceGrant
      .where(application_id: @oauth_app.id)
      .delete_all
    @oauth_app.destroy!
  end

  # ---------------------------------------------------------------------------
  # Step 1 — POST /oauth/authorize_device
  # ---------------------------------------------------------------------------

  test 'POST authorize_device returns device_code and user_code for valid client' do
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }

    assert_response :ok
    body = JSON.parse(response.body)
    assert body['device_code'].present?, 'expected device_code in response'
    assert body['user_code'].present?,   'expected user_code in response'
    assert body['verification_uri'].present?, 'expected verification_uri in response'
    assert_equal 900, body['expires_in']
    assert_equal 5,   body['interval']
  end

  test 'POST authorize_device includes verification_uri_complete with user_code' do
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }

    body = JSON.parse(response.body)
    assert body['verification_uri_complete'].include?(CGI.escape(body['user_code'])),
           'verification_uri_complete should contain the user_code'
  end

  test 'POST authorize_device creates a DeviceGrant record' do
    assert_difference 'Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.count', 1 do
      post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }
    end
  end

  test 'POST authorize_device with unknown client_id returns an error' do
    post '/oauth/authorize_device', params: { client_id: 'no-such-client' }

    assert_response :unauthorized
  end

  test 'POST authorize_device with a scope subset stores that scope' do
    post '/oauth/authorize_device', params: {
      client_id: @oauth_app.uid,
      scope: 'search'
    }

    assert_response :ok
    body = JSON.parse(response.body)
    grant = Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.find_by!(device_code: body['device_code'])
    assert_includes grant.scopes.split, 'search'
    assert_not_includes grant.scopes.split, 'upload'
  end

  # ---------------------------------------------------------------------------
  # Step 2 — GET /oauth/device  (user-facing verification page)
  # ---------------------------------------------------------------------------

  test 'GET /oauth/device requires authentication' do
    get '/oauth/device'
    assert_redirected_to new_user_session_path
  end

  test 'GET /oauth/device returns 200 for authenticated user' do
    sign_in @user
    get '/oauth/device'
    assert_response :success
  end

  test 'GET /oauth/device shows a user_code input form' do
    sign_in @user
    get '/oauth/device'
    assert_select 'input[name=?]', 'user_code'
    assert_match(/authorize/i, response.body)
  end

  test 'GET /oauth/device pre-fills user_code from query param' do
    sign_in @user
    get '/oauth/device', params: { user_code: 'ABCD-1234' }
    assert_select "input[name='user_code'][value='ABCD-1234']"
  end

  # ---------------------------------------------------------------------------
  # Step 2 — POST /oauth/device  (user approves the device)
  # ---------------------------------------------------------------------------

  test 'POST /oauth/device requires authentication' do
    grant = create_pending_grant
    post '/oauth/device', params: { user_code: grant.user_code }
    assert_redirected_to new_user_session_path
  end

  test 'POST /oauth/device with valid user_code sets resource_owner on the grant' do
    grant = create_pending_grant
    sign_in @user

    post '/oauth/device', params: { user_code: grant.user_code }

    grant.reload
    assert_equal @user.id, grant.resource_owner_id,
                 'resource_owner_id should be set to the approving user'
  end

  test 'POST /oauth/device with invalid user_code does not approve any grant' do
    sign_in @user

    assert_no_difference 'approved_grant_count' do
      post '/oauth/device', params: { user_code: 'INVALID-CODE' }
    end
  end

  test 'POST /oauth/device with expired user_code does not approve' do
    grant = create_pending_grant(expires_in: -1)
    sign_in @user

    assert_no_difference 'approved_grant_count' do
      post '/oauth/device', params: { user_code: grant.user_code }
    end
  end

  # ---------------------------------------------------------------------------
  # Step 3 — POST /oauth/token  (device polls for access token)
  # ---------------------------------------------------------------------------

  test 'POST /oauth/token returns authorization_pending before user approves' do
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }
    device_code = JSON.parse(response.body)['device_code']

    post '/oauth/token', params: {
      grant_type: DEVICE_GRANT_TYPE,
      device_code: device_code,
      client_id: @oauth_app.uid
    }

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal 'authorization_pending', body['error'],
                 "expected authorization_pending before user approves, got: #{body.inspect}"
  end

  test 'POST /oauth/token returns access_token after user approves' do
    # Step 1: device requests codes
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }
    assert_response :ok
    codes       = JSON.parse(response.body)
    device_code = codes['device_code']
    user_code   = codes['user_code']

    # Step 2: user approves
    sign_in @user
    post '/oauth/device', params: { user_code: user_code }

    # Step 3: device polls
    post '/oauth/token', params: {
      grant_type: DEVICE_GRANT_TYPE,
      device_code: device_code,
      client_id: @oauth_app.uid
    }

    assert_response :ok
    body = JSON.parse(response.body)
    assert body['access_token'].present?, "expected access_token in response, got: #{body.inspect}"
    assert_equal 'Bearer', body['token_type']
  end

  test 'POST /oauth/token creates an AccessToken record after approval' do
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid }
    codes       = JSON.parse(response.body)
    device_code = codes['device_code']
    user_code   = codes['user_code']

    sign_in @user
    post '/oauth/device', params: { user_code: user_code }

    assert_difference 'Doorkeeper::AccessToken.count', 1 do
      post '/oauth/token', params: {
        grant_type: DEVICE_GRANT_TYPE,
        device_code: device_code,
        client_id: @oauth_app.uid
      }
    end

    token = Doorkeeper::AccessToken.order(:created_at).last
    assert_equal @user.id,       token.resource_owner_id
    assert_equal @oauth_app.id,  token.application_id
  end

  test 'POST /oauth/token returns expired_token for an expired device_code' do
    grant = create_pending_grant(expires_in: -1)

    post '/oauth/token', params: {
      grant_type: DEVICE_GRANT_TYPE,
      device_code: grant.device_code,
      client_id: @oauth_app.uid
    }

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert_equal 'expired_token', body['error'],
                 "expected expired_token for expired device_code, got: #{body.inspect}"
  end

  test 'POST /oauth/token with unknown device_code returns an error' do
    post '/oauth/token', params: {
      grant_type: DEVICE_GRANT_TYPE,
      device_code: 'totally-unknown-device-code',
      client_id: @oauth_app.uid
    }

    assert_response :bad_request
    body = JSON.parse(response.body)
    assert body['error'].present?, 'expected an error for unknown device_code'
  end

  # ---------------------------------------------------------------------------
  # Full end-to-end flow
  # ---------------------------------------------------------------------------

  test 'complete device flow: request codes, approve, poll, use token on GraphQL' do
    # Step 1: device requests codes
    post '/oauth/authorize_device', params: { client_id: @oauth_app.uid, scope: 'search' }
    assert_response :ok
    codes       = JSON.parse(response.body)
    device_code = codes['device_code']
    user_code   = codes['user_code']

    # Step 2: user logs in and approves
    sign_in @user
    post '/oauth/device', params: { user_code: user_code }
    sign_out @user

    # Step 3: device polls and receives its token
    post '/oauth/token', params: {
      grant_type: DEVICE_GRANT_TYPE,
      device_code: device_code,
      client_id: @oauth_app.uid
    }
    assert_response :ok
    access_token = JSON.parse(response.body)['access_token']
    assert access_token.present?

    # Step 4: use the token on the GraphQL endpoint
    post graphql_path,
         params: { query: '{ __typename }' },
         headers: { 'Authorization' => "Bearer #{access_token}" },
         as: :json
    assert_response :ok
    body = JSON.parse(response.body)
    assert_nil(body['errors']&.find { |e| e['message'].include?('Unauthorized') })
  end

  private

  def create_pending_grant(expires_in: 900)
    Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
      application: @oauth_app,
      device_code: SecureRandom.hex(32),
      user_code: "TEST-#{SecureRandom.hex(4).upcase}",
      expires_in: expires_in,
      scopes: ''
    )
  end

  def approved_grant_count
    Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.where.not(resource_owner_id: nil).count
  end
end
