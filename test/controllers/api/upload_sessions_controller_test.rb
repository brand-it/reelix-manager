# frozen_string_literal: true

require 'test_helper'
require 'tus/storage/filesystem'
require 'json'

class TusUploadMutationsTest < ActionDispatch::IntegrationTest
  include ActiveJob::TestHelper

  # Use a per-process directory so parallel workers don't stomp on each other's uploads.
  def tus_storage_dir
    Rails.root.join('tmp', "tus_test_uploads_#{Process.pid}")
  end

  def finalized_storage_dir
    Rails.root.join('tmp', "finalized_test_uploads_#{Process.pid}")
  end

  setup do
    @original_storage = Tus::Server.opts[:storage]
    Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(tus_storage_dir)

    # Create a Doorkeeper access token for GraphQL auth (all scopes for mutation tests).
    user = create(:user)
    app  = Doorkeeper::Application.find_or_create_by!(name: 'TusTest') do |a|
      a.uid          = 'tus-test-app'
      a.redirect_uri = ''
      a.scopes       = 'all'
      a.confidential = false
    end
    token = Doorkeeper::AccessToken.create!(
      resource_owner_id: user.id,
      application: app,
      expires_in: 1.hour,
      scopes: 'all'
    )
    @auth_headers = { 'Authorization' => "Bearer #{token.token}" }
  end

  teardown do
    Tus::Server.opts[:storage] = @original_storage
    FileUtils.rm_rf(tus_storage_dir)
    FileUtils.rm_rf(finalized_storage_dir)
  end

  # ---------------------------------------------------------------------------
  # finalizeUpload
  # ---------------------------------------------------------------------------

  test 'finalizeUpload moves a complete tus file to the destination' do
    uid        = create_tus_upload('movie.mkv', content: 'FAKE VIDEO DATA')
    movie_dir  = finalized_storage_dir.to_s
    FileUtils.mkdir_p(movie_dir)
    create(:config_video, movie_dir: movie_dir)

    fake_movie = { 'title' => 'Batman Begins', 'release_date' => '2005-06-15', 'poster_path' => nil }
    TheMovieDb::Movie.define_singleton_method(:new) do |**|
      obj = Object.new
      obj.define_singleton_method(:results) { fake_movie }
      obj
    end

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}", tmdbId: 272 }) {
          destinationPath
          errors
        }
      }
    GQL

    # Verify job is enqueued
    assert_enqueued_jobs 1, only: PromoteUploadJob do
      post '/graphql', params: { query: mutation }, headers: @auth_headers, as: :json
    end

    assert_response :ok

    result = JSON.parse(response.body).dig('data', 'finalizeUpload')
    assert_empty result['errors']
    # Mutation returns immediately with nil destinationPath (async)
    assert_nil result['destinationPath']

    # Perform the enqueued job
    perform_enqueued_jobs

    # Verify file was moved by the job
    blob = VideoBlob.find_by(tmdb_id: 272)
    refute_nil blob
    assert File.exist?(blob.key), 'Expected finalized file to exist at destination'
  ensure
    begin
      TheMovieDb::Movie.singleton_class.remove_method(:new)
    rescue StandardError
      nil
    end
  end

  test 'finalizeUpload returns error for unknown upload id' do
    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "nonexistent-uid", tmdbId: 1 }) {
          destinationPath
          errors
        }
      }
    GQL

    post '/graphql', params: { query: mutation }, headers: @auth_headers, as: :json
    result = JSON.parse(response.body).dig('data', 'finalizeUpload')
    assert_includes result['errors'].first, 'Upload session not found'
  end

  test 'finalizeUpload returns error when upload is incomplete' do
    uid = create_tus_upload('partial.mkv', content: 'PARTIAL', declared_length: 999)

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}", tmdbId: 1 }) {
          destinationPath
          errors
        }
      }
    GQL

    post '/graphql', params: { query: mutation }, headers: @auth_headers, as: :json
    result = JSON.parse(response.body).dig('data', 'finalizeUpload')
    # Mutation returns immediately with empty errors (async)
    assert_empty result['errors']
  end

  test 'finalizeUpload uses extension from filename override' do
    uid        = create_tus_upload('original.mkv', content: 'DATA')
    movie_dir  = finalized_storage_dir.to_s
    FileUtils.mkdir_p(movie_dir)
    config     = create(:config_video, movie_dir: movie_dir)

    fake_movie = { 'title' => 'Batman Begins', 'release_date' => '2005-06-15', 'poster_path' => nil }
    TheMovieDb::Movie.define_singleton_method(:new) do |**|
      obj = Object.new
      obj.define_singleton_method(:results) { fake_movie }
      obj
    end

    mutation = <<~GQL
      mutation {
        finalizeUpload(input: { uploadId: "#{uid}", tmdbId: 272, filename: "renamed.avi" }) {
          destinationPath
          errors
        }
      }
    GQL

    # Verify job is enqueued
    assert_enqueued_jobs 1, only: PromoteUploadJob do
      post '/graphql', params: { query: mutation }, headers: @auth_headers, as: :json
    end

    # Perform the enqueued job and verify extension
    perform_enqueued_jobs
    blob = VideoBlob.find_by(tmdb_id: 272)
    refute_nil blob
    assert blob.key.end_with?('.avi'), "Expected .avi extension, got: #{blob.key}"
  ensure
    begin
      TheMovieDb::Movie.singleton_class.remove_method(:new)
    rescue StandardError
      nil
    end
    config&.destroy
    FileUtils.rm_rf(movie_dir)
  end

  private

  # Creates a tus upload file directly in the test storage directory,
  # simulating what the tus server would do after receiving all chunks.
  # Also creates a TusUploadSession record for the new DB-backed tracking.
  def create_tus_upload(filename, content:, declared_length: nil)
    uid = SecureRandom.uuid
    storage = Tus::Server.opts[:storage]
    actual_length = content.bytesize
    length = declared_length || actual_length

    info = {
      'Upload-Length' => length.to_s,
      'Upload-Offset' => actual_length.to_s,
      'Upload-Metadata' => "filename #{Base64.strict_encode64(filename)}"
    }

    storage.create_file(uid, info)
    storage.update_info(uid, info)
    storage.patch_file(uid, StringIO.new(content), info)

    # Create TusUploadSession record
    metadata = "filename #{Base64.strict_encode64(filename)}"
    TusUploadSession.create!(
      id: uid,
      filename: filename,
      upload_length: length,
      metadata: metadata,
      finalized: false
    )

    uid
  end
end
