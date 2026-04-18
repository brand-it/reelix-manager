require "test_helper"

class ErrorEntriesControllerTest < ActionDispatch::IntegrationTest
  setup do
    @admin = users(:admin)
    @regular_user = users(:regular)
    @error = error_entries(:one)
  end

  # Authentication tests
  test "should require authentication for index" do
    get error_entries_url
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for show" do
    get error_entry_url(@error)
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for acknowledge" do
    patch acknowledge_error_entry_url(@error)
    assert_redirected_to new_user_session_path
  end

  test "should require authentication for resolve" do
    patch resolve_error_entry_url(@error)
    assert_redirected_to new_user_session_path
  end

  # Authorization tests - non-admin users
  test "should deny access to non-admin users for index" do
    sign_in @regular_user
    get error_entries_url
    assert_redirected_to root_path
  end

  test "should deny access to non-admin users for show" do
    sign_in @regular_user
    get error_entry_url(@error)
    assert_redirected_to root_path
  end

  test "should deny access to non-admin users for acknowledge" do
    sign_in @regular_user
    patch acknowledge_error_entry_url(@error)
    assert_redirected_to root_path
  end

  test "should deny access to non-admin users for resolve" do
    sign_in @regular_user
    patch resolve_error_entry_url(@error)
    assert_redirected_to root_path
  end

  # Index action tests
  test "should allow admin users to access index" do
    sign_in @admin
    get error_entries_url
    assert_response :success
    assert_select "h4", "Error Tracking"
  end

  test "should display error entries in index" do
    sign_in @admin
    get error_entries_url
    assert_response :success
    assert_select "table"
  end

  test "should filter by error_class" do
    sign_in @admin
    get error_entries_url, params: { error_class: "ActiveRecord::RecordNotFound" }
    assert_response :success
    # Should only show errors with that class
    assert_match "ActiveRecord::RecordNotFound", response.body
  end

  test "should filter by status" do
    sign_in @admin
    get error_entries_url, params: { status: "unacknowledged" }
    assert_response :success
  end

  test "should show counts by status" do
    sign_in @admin
    get error_entries_url
    assert_response :success
    # Check that status counts are displayed
    assert_match /unacknowledged/i, response.body
    assert_match /acknowledged/i, response.body
    assert_match /resolved/i, response.body
  end

  # Show action tests
  test "should show error details for admin" do
    sign_in @admin
    get error_entry_url(@error)
    assert_response :success
    assert_select "h2", @error.error_message
    assert_select "p", @error.error_class
  end

  test "should display backtrace" do
    sign_in @admin
    get error_entry_url(@error)
    assert_response :success
    # Backtrace is HTML-escaped in the view
    assert_match CGI.escapeHTML(@error.backtrace), response.body
  end


  test "should display similar errors" do
    # error_entries(:one) and error_entries(:four) have the same fingerprint
    sign_in @admin
    get error_entry_url(@error)
    assert_response :success
    # Should show at least 2 similar errors (one and four)
    assert_select ".similar-error", count: 2
  end

  # Acknowledge action tests
  test "should acknowledge error" do
    sign_in @admin
    assert_equal "unacknowledged", @error.status
    patch acknowledge_error_entry_url(@error)
    assert_redirected_to error_entries_path
    assert_equal "Error acknowledged.", flash[:notice]
    @error.reload
    assert_equal "acknowledged", @error.status
  end

  test "should redirect to error_entries_path after acknowledge" do
    sign_in @admin
    patch acknowledge_error_entry_url(@error)
    assert_redirected_to error_entries_path
  end

  # Resolve action tests
  test "should resolve error" do
    sign_in @admin
    assert_equal "unacknowledged", @error.status
    patch resolve_error_entry_url(@error)
    assert_redirected_to error_entries_path
    assert_equal "Error resolved.", flash[:notice]
    @error.reload
    assert_equal "resolved", @error.status
  end

  test "should redirect to error_entries_path after resolve" do
    sign_in @admin
    patch resolve_error_entry_url(@error)
    assert_redirected_to error_entries_path
  end

  # Edge cases
  test "should handle missing error in show" do
    sign_in @admin
    get error_entry_url(id: 99999)
    assert_response :not_found
  end

  test "should handle missing error in acknowledge" do
    sign_in @admin
    patch acknowledge_error_entry_url(id: 99999)
    assert_response :not_found
  end

  test "should handle missing error in resolve" do
    sign_in @admin
    patch resolve_error_entry_url(id: 99999)
    assert_response :not_found
  end
end
