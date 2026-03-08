require "test_helper"

class UploadSessionTest < ActiveSupport::TestCase
  test "valid with required attributes" do
    session = UploadSession.new(filename: "video.mkv", total_chunks: 5)
    assert session.valid?
  end

  test "invalid without filename" do
    session = UploadSession.new(total_chunks: 3)
    assert_not session.valid?
    assert_includes session.errors[:filename], "can't be blank"
  end

  test "invalid without total_chunks" do
    session = UploadSession.new(filename: "video.mkv")
    assert_not session.valid?
  end

  test "invalid with zero total_chunks" do
    session = UploadSession.new(filename: "video.mkv", total_chunks: 0)
    assert_not session.valid?
  end

  test "invalid with unknown status" do
    session = UploadSession.new(filename: "video.mkv", total_chunks: 1, status: "unknown")
    assert_not session.valid?
  end

  test "auto-generates uuid on create" do
    session = UploadSession.create!(filename: "auto.mkv", total_chunks: 1)
    assert_not_nil session.id
    assert_match(/\A[0-9a-f-]{36}\z/, session.id)
  end

  test "upload_complete? returns true when all chunk files are present on disk" do
    session = upload_sessions(:upload_session_complete)
    FileUtils.mkdir_p(session.chunks_dir)
    FileUtils.touch(session.chunk_path(1))
    assert session.upload_complete?
  ensure
    FileUtils.rm_rf(session.chunks_dir)
  end

  test "upload_complete? returns false when chunks are missing" do
    session = upload_sessions(:upload_session_uploading)
    # No chunk files written — both chunks are absent
    assert_not session.upload_complete?
  end

  test "missing_chunks returns the correct absent chunk numbers" do
    session = upload_sessions(:upload_session_uploading)
    FileUtils.mkdir_p(session.chunks_dir)
    FileUtils.touch(session.chunk_path(1))
    assert_equal [ 2 ], session.missing_chunks
  ensure
    FileUtils.rm_rf(session.chunks_dir)
  end

  test "chunk_path returns predictable zero-padded path" do
    session = upload_sessions(:upload_session_one)
    expected = session.chunks_dir.join("chunk_000001")
    assert_equal expected.to_s, session.chunk_path(1).to_s
  end

  test "assembled_file_path combines destination_path and filename" do
    session = upload_sessions(:upload_session_one)
    assert_equal "/tmp/test_uploads/movie.mkv", session.assembled_file_path
  end

  test "assembled_file_path returns nil when destination_path is blank" do
    session = UploadSession.new(filename: "video.mkv", total_chunks: 1)
    assert_nil session.assembled_file_path
  end
end
