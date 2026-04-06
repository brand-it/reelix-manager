require "test_helper"

class SetupsControllerTest < ActionDispatch::IntegrationTest
  test "GET /setup redirects to root when users already exist" do
    create(:user)
    get setup_path
    assert_redirected_to root_path
  end

  test "GET /setup is accessible when no users exist" do
    User.delete_all
    get setup_path
    assert_response :success
  end

  test "POST /setup creates admin user and signs them in when no users exist" do
    User.delete_all
    assert_difference "User.count", 1 do
      post setup_path, params: { user: { email: "newadmin@example.com", password: "password", password_confirmation: "password" } }
    end
    assert User.last.admin?
    assert_redirected_to root_path
  end

  test "POST /setup is blocked when users already exist" do
    create(:user)
    assert_no_difference "User.count" do
      post setup_path, params: { user: { email: "hacker@example.com", password: "password", password_confirmation: "password" } }
    end
    assert_redirected_to root_path
  end

  test "POST /setup renders form again on validation error" do
    User.delete_all
    post setup_path, params: { user: { email: "", password: "password", password_confirmation: "password" } }
    assert_response :unprocessable_entity
  end
end
