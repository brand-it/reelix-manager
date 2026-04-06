require "test_helper"

class AuthProtectionTest < ActionDispatch::IntegrationTest
  test "unauthenticated request to settings is redirected to login" do
    get new_config_video_path
    assert_redirected_to new_user_session_path
  end

  test "unauthenticated request redirects to /setup when no users exist" do
    User.delete_all
    get new_config_video_path
    assert_redirected_to setup_path
  end

  test "authenticated user can access settings" do
    user = create(:user)
    sign_in user
    # The videos controller may redirect to edit if config already exists — either way,
    # a 2xx or internal 3xx confirms auth passed (we don't get redirected to sign-in).
    get new_config_video_path
    assert_not_equal new_user_session_path, response.location
    assert response.successful? || response.redirect?
  end

  test "authenticated user can access devices page" do
    user = create(:user)
    sign_in user
    get devices_path
    assert_response :success
  end

  test "authenticated user can reach the OAuth device authorization page" do
    sign_in create(:user)
    get oauth_device_authorizations_index_path
    assert_response :success
    assert_select "input[name=user_code]"
  end

  test "unauthenticated request to OAuth device page redirects to sign_in" do
    get oauth_device_authorizations_index_path
    assert_redirected_to new_user_session_path
  end

  # ── Layout ──────────────────────────────────────────────────────────────────

  test "navbar renders with brand and nav links when authenticated" do
    sign_in create(:user)
    get devices_path
    assert_select "nav.navbar"
    assert_select "a.navbar-brand", text: /Reelix Manager/i
    assert_select "a[href=?]", api_docs_path, text: /API Docs/i
  end
end
