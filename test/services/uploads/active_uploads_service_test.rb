# frozen_string_literal: true

require 'test_helper'
require 'json'

class UploadsActiveUploadsServiceTest < ActiveSupport::TestCase
  setup do
    @storage_dir = Dir.mktmpdir('active_uploads_service')
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

  test 'returns incomplete uploads with byte progress' do
    create_upload(uid: 'upload-1', filename: 'movie.mkv', length: 1000, offset: 250)

    upload = Uploads::ActiveUploadsService.call.first

    assert_equal 'upload-1', upload.id
    assert_equal 'movie.mkv', upload.filename
    assert_equal 1000, upload.upload_length
    assert_equal 250, upload.upload_offset
    assert_equal 750, upload.bytes_remaining
    assert_equal 25, upload.progress_percent
    assert_equal 'uploading', upload.status
    assert_not upload.upload_complete
  end

  test 'marks fully uploaded files as ready_to_finalize' do
    create_upload(uid: 'upload-2', filename: 'episode.mkv', length: 500, offset: 500)

    upload = Uploads::ActiveUploadsService.call.first

    assert_equal 'ready_to_finalize', upload.status
    assert upload.upload_complete
    assert_equal 0, upload.bytes_remaining
    assert_equal 100, upload.progress_percent
  end

  test 'returns most recently updated uploads first' do
    create_upload(uid: 'older', filename: 'older.mkv', length: 100, offset: 10)
    sleep 1
    create_upload(uid: 'newer', filename: 'newer.mkv', length: 100, offset: 20)

    assert_equal %w[newer older], Uploads::ActiveUploadsService.call.map(&:id)
  end

  test 'gracefully skips uploads with malformed .info files' do
    # Create a valid upload
    create_upload(uid: 'valid-upload', filename: 'valid.mkv', length: 1000, offset: 250)

    # Create a malformed .info file
    File.binwrite(File.join(@storage_dir, 'malformed.info'), 'not valid json {{{')

    # Service should not raise an error
    result = Uploads::ActiveUploadsService.call

    # Should only return the valid upload
    assert_equal 1, result.size
    assert_equal 'valid-upload', result.first.id
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
