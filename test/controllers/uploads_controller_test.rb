# frozen_string_literal: true

require 'test_helper'
require 'json'

class UploadsControllerTest < ActionDispatch::IntegrationTest
  include Devise::Test::IntegrationHelpers

  setup do
    @user = create(:user)
    sign_in @user

    @storage_dir = Dir.mktmpdir('uploads_controller_uploads')
    @original_storage = Tus::Server.opts[:storage]
    @original_expiration_time = Tus::Server.opts[:expiration_time]

    storage_dir = @storage_dir
    fake_storage = Object.new
    fake_storage.define_singleton_method(:directory) { Pathname(storage_dir) }

    Tus::Server.opts[:storage] = fake_storage
    Tus::Server.opts[:expiration_time] = 48.hours
  end

  teardown do
    Tus::Server.opts[:storage] = @original_storage
    Tus::Server.opts[:expiration_time] = @original_expiration_time
    FileUtils.rm_rf(@storage_dir)
  end

  test 'index shows active uploads and recent uploads' do
    # Create TusUploadSession and tus filesystem files
    metadata = Base64.strict_encode64('movie.mkv')
    File.binwrite(File.join(@storage_dir, 'upload-1'), 'x' * 250)
    File.binwrite(
      File.join(@storage_dir, 'upload-1.info'),
      JSON.generate(
        'Upload-Length' => '1000',
        'Upload-Offset' => '250',
        'Upload-Metadata' => "filename #{metadata}"
      )
    )
    TusUploadSession.create!(
      id: 'upload-1',
      filename: 'movie.mkv',
      upload_length: 1000,
      metadata: "filename #{metadata}",
      finalized: false
    )
    create(:video_blob, title: 'Batman Begins', year: 2005, created_at: 1.minute.ago)

    get uploads_path

    assert_response :success
    assert_includes response.body, 'Current uploads'
    assert_includes response.body, 'movie.mkv'
    assert_includes response.body, '25%'
    assert_includes response.body, 'Recently uploaded files'
    assert_includes response.body, 'Batman Begins'
  end

  test 'index responds with turbo_stream format when Accept header is set' do
    TusUploadSession.create!(
      id: 'upload-1',
      filename: 'movie.mkv',
      upload_length: 1000,
      metadata: '',
      finalized: false
    )

    # NOTE: Accept header must not contain */* or Rails will treat it as browser-like
    # and ignore the Accept header, defaulting to HTML
    get uploads_path, headers: { 'Accept' => 'text/vnd.turbo-stream.html, text/html' }

    assert_response :success
    assert_includes response.content_type, 'text/vnd.turbo-stream.html'
    assert_includes response.body, '<turbo-stream'
  end

  test 'index responds with html format by default' do
    TusUploadSession.create!(
      id: 'upload-1',
      filename: 'movie.mkv',
      upload_length: 1000,
      metadata: '',
      finalized: false
    )

    get uploads_path

    assert_response :success
    assert_includes response.content_type, 'text/html'
  end

  private

  def create_upload(uid:, filename:, length:, offset:)
    File.binwrite(File.join(@storage_dir, uid), 'x' * offset)

    metadata = Base64.strict_encode64(filename)
    info = {
      'Upload-Length' => length.to_s,
      'Upload-Offset' => offset.to_s,
      'Upload-Metadata' => "filename #{metadata}"
    }
    File.binwrite(File.join(@storage_dir, "#{uid}.info"), JSON.generate(info))
  end
end
