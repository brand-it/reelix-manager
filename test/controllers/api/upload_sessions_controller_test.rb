require "test_helper"
require "tus/storage/filesystem"
require "json"

class TusUploadMutationsTest < ActionDispatch::IntegrationTest
  TUS_STORAGE_DIR = Rails.root.join("tmp", "tus_test_uploads")

  setup do
    @original_storage = Tus::Server.opts[:storage]
    Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(TUS_STORAGE_DIR)
  end

  teardown do
    Tus::Server.opts[:storage] = @original_storage
    FileUtils.rm_rf(TUS_STORAGE_DIR)
    FileUtils.rm_rf(Rails.root.join("tmp", "finalized_test_uploads"))
  end

  # ---------------------------------------------------------------------------
  # finalizeUpload
  # ---------------------------------------------------------------------------

  test "finalizeUpload moves a complete tus file to the destination" do
    uid = create_tus_upload("movie.mkv", content: "FAKE VIDEO DATA")

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}" }) {
          destinationPath
          filename
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    assert_response :ok

    result = JSON.parse(response.body).dig("data", "finalizeUpload")
    assert_empty result["errors"]
    assert_equal "movie.mkv", result["filename"]
    assert File.exist?(result["destinationPath"]), "Expected finalized file to exist at destination"
  end

  test "finalizeUpload returns error for unknown upload id" do
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "nonexistent-uid" }) {
          destinationPath
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    result = JSON.parse(response.body).dig("data", "finalizeUpload")
    assert_includes result["errors"].first, "Upload not found"
  end

  test "finalizeUpload returns error when upload is incomplete" do
    uid = create_tus_upload("partial.mkv", content: "PARTIAL", declared_length: 999)

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}" }) {
          destinationPath
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    result = JSON.parse(response.body).dig("data", "finalizeUpload")
    assert_includes result["errors"].first, "incomplete"
  end

  test "finalizeUpload accepts a filename override" do
    uid = create_tus_upload("original.mkv", content: "DATA")

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}", filename: "renamed.mkv" }) {
          filename
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    result = JSON.parse(response.body).dig("data", "finalizeUpload")
    assert_empty result["errors"]
    assert_equal "renamed.mkv", result["filename"]
  end

  # ---------------------------------------------------------------------------
  # abortUpload
  # ---------------------------------------------------------------------------

  test "abortUpload deletes an in-progress upload" do
    uid = create_tus_upload("to_abort.mkv", content: "PARTIAL", declared_length: 999)

    mutation = <<~GQL
      mutation {
        abortUpload(input: { uploadId: "#{uid}" }) {
          success
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    result = JSON.parse(response.body).dig("data", "abortUpload")
    assert result["success"]
    assert_empty result["errors"]

    # File should be gone from tus storage.
    assert_raises(Tus::NotFound) { Tus::Server.opts[:storage].read_info(uid) }
  end

  test "abortUpload returns error for unknown upload id" do
    mutation = <<~GQL
      mutation {
        abortUpload(input: { uploadId: "ghost-uid" }) {
          success
          errors
        }
      }
    GQL

    post "/graphql", params: { query: mutation }, as: :json
    result = JSON.parse(response.body).dig("data", "abortUpload")
    assert_not result["success"]
    assert_includes result["errors"].first, "Upload not found"
  end

  private

  # Creates a tus upload file directly in the test storage directory,
  # simulating what the tus server would do after receiving all chunks.
  def create_tus_upload(filename, content:, declared_length: nil)
    uid = SecureRandom.uuid
    storage = Tus::Server.opts[:storage]
    actual_length = content.bytesize
    length = declared_length || actual_length

    info = {
      "Upload-Length" => length.to_s,
      "Upload-Offset" => actual_length.to_s,
      "Upload-Metadata" => "filename #{Base64.strict_encode64(filename)}"
    }

    storage.create_file(uid, info)
    storage.update_info(uid, info)
    storage.patch_file(uid, StringIO.new(content), info)

    uid
  end
end
