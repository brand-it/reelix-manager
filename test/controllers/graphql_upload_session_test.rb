# frozen_string_literal: true

require 'test_helper'

class GraphqlUploadSessionTest < ActionDispatch::IntegrationTest
  setup do
    @user = create(:user)

    @no_scope_app = Doorkeeper::Application.find_or_create_by!(name: 'TestAppNoScope') do |a|
      a.uid          = SecureRandom.uuid
      a.redirect_uri = ''
      a.scopes       = ''
      a.confidential = false
    end
    @no_scope_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: @no_scope_app,
      expires_in: 1.hour,
      scopes: ''
    )

    @upload_app = Doorkeeper::Application.find_or_create_by!(name: 'TestAppUpload') do |a|
      a.uid          = SecureRandom.uuid
      a.redirect_uri = ''
      a.scopes       = 'upload'
      a.confidential = false
    end
    @upload_token = Doorkeeper::AccessToken.create!(
      resource_owner_id: @user.id,
      application: @upload_app,
      expires_in: 1.hour,
      scopes: 'upload'
    )
  end

  # ---------------------------------------------------------------------------
  # Single upload session query
  # ---------------------------------------------------------------------------

  test 'upload_session query returns specific session by id' do
    storage_dir = Dir.mktmpdir('graphql_upload_session')
    original_storage = Tus::Server.opts[:storage]
    original_expiration_time = Tus::Server.opts[:expiration_time]

    storage_dir_for_double = storage_dir
    fake_storage = Object.new
    fake_storage.define_singleton_method(:directory) { Pathname(storage_dir_for_double) }
    Tus::Server.opts[:storage] = fake_storage
    Tus::Server.opts[:expiration_time] = 48.hours

    # Create tus filesystem files for upload_offset computation
    metadata = Base64.strict_encode64('movie.mkv')
    File.binwrite(File.join(storage_dir, 'upload-1'), 'x' * 250)
    File.binwrite(
      File.join(storage_dir, 'upload-1.info'),
      JSON.generate(
        'Upload-Length' => '1000',
        'Upload-Offset' => '250',
        'Upload-Metadata' => "filename #{metadata}"
      )
    )

    # Create TusUploadSession record
    TusUploadSession.create!(
      id: 'upload-1',
      filename: 'movie.mkv',
      upload_length: 1000,
      metadata: "filename #{metadata}",
      finalized: false
    )

    query = <<~GQL
      {
        uploadSession(id: "upload-1") {
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
         headers: { 'Authorization' => "Bearer #{@upload_token.token}" },
         as: :json

    assert_response :success
    data = JSON.parse(response.body).dig('data', 'uploadSession')
    assert_equal 'upload-1', data['id']
    assert_equal 'movie.mkv', data['filename']
    assert_equal '1000', data['uploadLength']
    assert_equal '250', data['uploadOffset']
    assert_equal 25, data['progressPercent']
    assert_equal '750', data['bytesRemaining']
    assert_equal 'uploading', data['status']
  ensure
    TusUploadSession.find_by(id: 'upload-1')&.destroy
    Tus::Server.opts[:storage] = original_storage
    Tus::Server.opts[:expiration_time] = original_expiration_time
    FileUtils.rm_rf(storage_dir) if storage_dir
  end

  test 'upload_session query returns null for non-existent id' do
    query = <<~GQL
      {
        uploadSession(id: "non-existent-id") {
          id
        }
      }
    GQL

    post graphql_path,
         params: { query: query },
         headers: { 'Authorization' => "Bearer #{@upload_token.token}" },
         as: :json

    assert_response :success
    data = JSON.parse(response.body).dig('data', 'uploadSession')
    assert_nil data
  end

  test 'upload_session query is forbidden without upload scope' do
    query = <<~GQL
      {
        uploadSession(id: "some-id") {
          id
        }
      }
    GQL

    post graphql_path,
         params: { query: query },
         headers: { 'Authorization' => "Bearer #{@no_scope_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    errors = Array(body['errors']).map { |e| e['message'] }
    assert errors.any? { |message| message.include?('upload scope required') },
           "Expected upload scope error, got: #{errors.inspect}"
  end

  # ---------------------------------------------------------------------------
  # Large byte value handling (regression test for 500 error)
  # ---------------------------------------------------------------------------

  test 'uploadSessions handles large byte values exceeding 32-bit integer limits' do
    storage_dir = Dir.mktmpdir('graphql_large_bytes')
    original_storage = Tus::Server.opts[:storage]
    original_expiration_time = Tus::Server.opts[:expiration_time]

    storage_dir_for_double = storage_dir
    fake_storage = Object.new
    fake_storage.define_singleton_method(:directory) { Pathname(storage_dir_for_double) }
    Tus::Server.opts[:storage] = fake_storage
    Tus::Server.opts[:expiration_time] = 48.hours

    # Create tus filesystem files for upload_offset computation
    metadata = Base64.strict_encode64('large_file.mkv')
    File.binwrite(File.join(storage_dir, 'large-upload'), 'x' * 1_000_000)
    File.binwrite(
      File.join(storage_dir, 'large-upload.info'),
      JSON.generate(
        'Upload-Length' => '4831838208',
        'Upload-Offset' => '4485808128',
        'Upload-Metadata' => "filename #{metadata}"
      )
    )

    # Create TusUploadSession record
    TusUploadSession.create!(
      id: 'large-upload',
      filename: 'large_file.mkv',
      upload_length: 4_831_838_208,
      metadata: "filename #{metadata}",
      finalized: false
    )

    query = <<~GQL
      {
        uploadSessions {
          id
          uploadLength
          uploadOffset
          bytesRemaining
        }
      }
    GQL

    post graphql_path,
         params: { query: query },
         headers: { 'Authorization' => "Bearer #{@upload_token.token}" },
         as: :json

    assert_response :success
    body = JSON.parse(response.body)
    assert_nil body['errors'], "Expected no errors, got: #{body['errors'].inspect}"
    data = body.dig('data', 'uploadSessions')
    assert_equal 1, data.size
    assert_equal '4831838208', data.first['uploadLength']
    assert_equal '4485808128', data.first['uploadOffset']
    assert_equal '346030080', data.first['bytesRemaining']
  ensure
    TusUploadSession.find_by(id: 'large-upload')&.destroy
    Tus::Server.opts[:storage] = original_storage
    Tus::Server.opts[:expiration_time] = original_expiration_time
    FileUtils.rm_rf(storage_dir) if storage_dir
  end
end
