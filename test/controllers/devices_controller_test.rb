require "test_helper"

class DevicesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user       = create(:user)
    @admin      = create(:user, admin: true)
    @oauth_app  = Doorkeeper::Application.create!(
      name: "Test App",
      uid: "test-uid-#{SecureRandom.hex(4)}",
      secret: "test-secret",
      redirect_uri: "urn:ietf:wg:oauth:2.0:oob",
      confidential: false
    )
  end

  teardown do
    Doorkeeper::AccessToken.delete_all
    Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.delete_all
    Doorkeeper::Application.delete_all
  end

  # ---------------------------------------------------------------------------
  # GET /devices
  # ---------------------------------------------------------------------------
  test "GET index requires authentication" do
    get devices_path
    assert_redirected_to new_user_session_path
  end

  test "GET index returns 200 for signed-in user" do
    sign_in @user
    get devices_path
    assert_response :success
  end

  test "GET index shows empty state when no tokens or grants" do
    sign_in @user
    get devices_path
    assert_select ".alert-info", /No authorized devices yet/
  end

  test "GET index shows user's access token" do
    Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @user
    get devices_path
    assert_select "td", @oauth_app.name
    assert_select ".alert-info", count: 0
  end

  test "GET index shows user's authorized pending device grant" do
    Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 900,
      scopes: "",
      device_code: "device-code-#{SecureRandom.hex(16)}"
    )
    sign_in @user
    get devices_path
    assert_select ".badge", /Pending/
  end

  test "GET index does not show another user's access token" do
    other = create(:user)
    Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: other.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @user
    get devices_path
    assert_select ".alert-info", /No authorized devices yet/
  end

  test "GET index as admin shows all tokens" do
    Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @admin
    get devices_path
    assert_select "td", @oauth_app.name
  end

  # ---------------------------------------------------------------------------
  # DELETE /devices/:id
  # ---------------------------------------------------------------------------
  test "DELETE destroy revokes own access token" do
    token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @user
    delete device_path(token)
    assert_redirected_to devices_path
    assert token.reload.revoked?
  end

  test "DELETE destroy cannot revoke another user's token" do
    other = create(:user)
    token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: other.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @user
    delete device_path(token)
    assert_redirected_to devices_path
    assert_equal "Device not found.", flash[:alert]
    assert_not token.reload.revoked?
  end

  test "DELETE destroy as admin revokes any token" do
    token = Doorkeeper::AccessToken.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 1.year.to_i,
      scopes: ""
    )
    sign_in @admin
    delete device_path(token)
    assert_redirected_to devices_path
    assert token.reload.revoked?
  end

  # ---------------------------------------------------------------------------
  # DELETE /devices/grant/:id
  # ---------------------------------------------------------------------------
  test "DELETE destroy_grant cancels own pending device grant" do
    grant = Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 900,
      scopes: "",
      device_code: "device-code-#{SecureRandom.hex(16)}"
    )
    sign_in @user
    assert_difference("Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.count", -1) do
      delete grant_devices_path(id: grant.id)
    end
    assert_redirected_to devices_path
    assert_equal "Pending device authorization cancelled.", flash[:notice]
  end

  test "DELETE destroy_grant cannot cancel another user's device grant" do
    other = create(:user)
    grant = Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
      application: @oauth_app,
      resource_owner_id: other.id,
      expires_in: 900,
      scopes: "",
      device_code: "device-code-#{SecureRandom.hex(16)}"
    )
    sign_in @user
    assert_no_difference("Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.count") do
      delete grant_devices_path(id: grant.id)
    end
    assert_redirected_to devices_path
    assert_equal "Pending device not found.", flash[:alert]
  end

  test "DELETE destroy_grant as admin cancels any pending grant" do
    grant = Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.create!(
      application: @oauth_app,
      resource_owner_id: @user.id,
      expires_in: 900,
      scopes: "",
      device_code: "device-code-#{SecureRandom.hex(16)}"
    )
    sign_in @admin
    assert_difference("Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.count", -1) do
      delete grant_devices_path(id: grant.id)
    end
    assert_redirected_to devices_path
  end
end
