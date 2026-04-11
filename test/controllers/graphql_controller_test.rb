require "test_helper"

class GraphqlControllerTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)
    app = Doorkeeper::Application.find_or_create_by!(name: "Test") do |a|
      a.uid          = "test-app-#{SecureRandom.hex(4)}"
      a.redirect_uri = ""
      a.scopes       = "all search upload"
      a.confidential = false
    end
    @all_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: app,
      expires_in: 1.hour,
      scopes: "all"
    )
    @search_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: app,
      expires_in: 1.hour,
      scopes: "search"
    )
    @upload_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: app,
      expires_in: 1.hour,
      scopes: "upload"
    )
    @no_scope_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: app,
      expires_in: 1.hour,
      scopes: ""
    )
  end

  # ---------------------------------------------------------------------------
  # Authentication
  # ---------------------------------------------------------------------------

  test "returns 401 when no token and no session" do
    post graphql_path, params: { query: "{ __typename }" }, as: :json
    assert_response :unauthorized
    body = JSON.parse(response.body)
    assert_equal "Unauthorized", body.dig("errors", 0, "message")
  end

  test "returns 401 when Bearer token is invalid" do
    post graphql_path,
         params: { query: "{ __typename }" },
         headers: { "Authorization" => "Bearer invalid-token-xyz" },
         as: :json
    assert_response :unauthorized
  end

  # ---------------------------------------------------------------------------
  # Session-based auth (GraphiQL / browser)
  # ---------------------------------------------------------------------------

  test "session user can access GraphQL without a token" do
    sign_in @user
    post graphql_path, params: { query: "{ __typename }" }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["errors"]
  end

  test "session user can run search query without scope restrictions" do
    sign_in @user
    query = <<~GQL
      { searchMulti(query: "test") { results { title } } }
    GQL
    post graphql_path, params: { query: query }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }
    assert errors.none? { |m| m.include?("scope required") },
           "Session user should not hit scope errors, got: #{errors.inspect}"
  end

  test "session user can run upload mutation without scope restrictions" do
    sign_in @user
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "fake-upload-id" }) {
          destinationPath
          errors
        }
      }
    GQL
    post graphql_path, params: { query: mutation }, as: :json
    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }
    assert errors.none? { |m| m.include?("scope required") },
           "Session user should not hit scope errors, got: #{errors.inspect}"
  end

  # ---------------------------------------------------------------------------
  # Query scope enforcement
  # ---------------------------------------------------------------------------

  test "__typename introspection passes with any valid token (no field scope needed)" do
    post graphql_path,
         params: { query: "{ __typename }" },
         headers: { "Authorization" => "Bearer #{@no_scope_token.token}" },
         as: :json
    assert_response :success
  end

  test "search query succeeds with all scope" do
    query = <<~GQL
      { searchMulti(query: "test") { results { title } } }
    GQL
    post graphql_path,
         params: { query: query },
         headers: { "Authorization" => "Bearer #{@all_token.token}" },
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["errors"]&.find { |e| e["message"].include?("scope required") }
  end

  test "search query succeeds with search scope" do
    query = <<~GQL
      { searchMulti(query: "test") { results { title } } }
    GQL
    post graphql_path,
         params: { query: query },
         headers: { "Authorization" => "Bearer #{@search_token.token}" },
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body["errors"]&.find { |e| e["message"].include?("scope required") }
  end

  test "search query is forbidden with upload-only scope" do
    query = <<~GQL
      { searchMulti(query: "test") { results { title } } }
    GQL
    post graphql_path,
         params: { query: query },
         headers: { "Authorization" => "Bearer #{@upload_token.token}" },
         as: :json
    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }
    assert errors.any? { |m| m.include?("search scope required") },
           "Expected search scope error, got: #{errors.inspect}"
  end

  # ---------------------------------------------------------------------------
  # Mutation scope enforcement
  # ---------------------------------------------------------------------------

  test "mutation returns forbidden error when token only has search scope" do
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "fake-upload-id", tmdbId: 1 }) {
          destinationPath
          errors
        }
      }
    GQL

    post graphql_path,
         params: { query: mutation },
         headers: { "Authorization" => "Bearer #{@search_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }
    assert errors.any? { |m| m.include?("upload scope required") },
           "Expected upload scope error, got: #{errors.inspect}"
  end

  test "mutation passes scope check with upload scope" do
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "fake-upload-id", tmdbId: 1 }) {
          destinationPath
          errors
        }
      }
    GQL

    post graphql_path,
         params: { query: mutation },
         headers: { "Authorization" => "Bearer #{@upload_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }.join(" ")
    assert_no_match "upload scope required", errors
    assert_no_match "search scope required", errors
  end

  test "mutation passes scope check with all scope" do
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "fake-upload-id", tmdbId: 1 }) {
          destinationPath
          errors
        }
      }
    GQL

    post graphql_path,
         params: { query: mutation },
         headers: { "Authorization" => "Bearer #{@all_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }.join(" ")
    assert_no_match "upload scope required", errors
    assert_no_match "search scope required", errors
  end

  test "uploadSessions query passes with upload scope and returns live progress" do
    storage_dir = Dir.mktmpdir("graphql_upload_sessions")
    original_storage = Tus::Server.opts[:storage]
    original_expiration_time = Tus::Server.opts[:expiration_time]

    storage_dir_for_double = storage_dir
    fake_storage = Object.new
    fake_storage.define_singleton_method(:directory) { Pathname(storage_dir_for_double) }
    Tus::Server.opts[:storage] = fake_storage
    Tus::Server.opts[:expiration_time] = 48.hours

    metadata = Base64.strict_encode64("movie.mkv")
    File.binwrite(File.join(storage_dir, "upload-1"), "x" * 250)
    File.binwrite(
      File.join(storage_dir, "upload-1.info"),
      JSON.generate(
        "Upload-Length" => "1000",
        "Upload-Offset" => "250",
        "Upload-Metadata" => "filename #{metadata}"
      )
    )

    query = <<~GQL
      {
        uploadSessions {
          id
          filename
          uploadLength
          uploadOffset
          progressPercent
          bytesRemaining
          status
        }
      }
    GQL

    post graphql_path,
         params: { query: query },
         headers: { "Authorization" => "Bearer #{@upload_token.token}" },
         as: :json

    assert_response :success
    data = JSON.parse(response.body).dig("data", "uploadSessions")
    assert_equal 1, data.size
    assert_equal "upload-1", data.first["id"]
    assert_equal "movie.mkv", data.first["filename"]
    assert_equal 1000, data.first["uploadLength"]
    assert_equal 250, data.first["uploadOffset"]
    assert_equal 25, data.first["progressPercent"]
    assert_equal 750, data.first["bytesRemaining"]
    assert_equal "uploading", data.first["status"]
  ensure
    Tus::Server.opts[:storage] = original_storage
    Tus::Server.opts[:expiration_time] = original_expiration_time
    FileUtils.rm_rf(storage_dir) if storage_dir
  end

  test "uploadSessions query is forbidden without upload scope" do
    query = <<~GQL
      {
        uploadSessions {
          id
        }
      }
    GQL

    post graphql_path,
         params: { query: query },
         headers: { "Authorization" => "Bearer #{@search_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body["errors"]).map { |e| e["message"] }
    assert errors.any? { |message| message.include?("upload scope required") },
           "Expected upload scope error, got: #{errors.inspect}"
  end
end
