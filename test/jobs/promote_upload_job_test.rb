# frozen_string_literal: true

require 'test_helper'

class PromoteUploadJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  def setup_tus_upload(uid:, content:)
    dir = Dir.mktmpdir('tus_test_')
    File.write(File.join(dir, uid), content)

    encoded_filename = Base64.strict_encode64('movie.mkv')
    fake_info = {
      'Upload-Length' => content.bytesize.to_s,
      'Upload-Offset' => content.bytesize.to_s,
      'Upload-Metadata' => "filename #{encoded_filename}"
    }

    fake_storage = Object.new.tap do |s|
      s.define_singleton_method(:read_info) { |_uid| fake_info }
      s.define_singleton_method(:delete_file) { |*| nil }
      s.define_singleton_method(:directory) { dir }
    end

    @original_tus_opts = Tus::Server.opts.dup
    Tus::Server.opts[:storage] = fake_storage
    Tus::Server.opts[:expiration_time] = 48.hours

    @tus_session = TusUploadSession.create!(
      id: uid,
      filename: 'movie.mkv',
      upload_length: content.bytesize,
      metadata: fake_info['Upload-Metadata'],
      finalized: false
    )

    @dir = dir
    fake_info
  end

  def teardown
    TusUploadSession.find_by(id: @tus_session&.id)&.destroy if defined?(@tus_session)
    FileUtils.rm_rf(@dir) if defined?(@dir)
    Tus::Server.opts.replace(@original_tus_opts) if defined?(@original_tus_opts)
    FileUtils.rm_rf(@movie_dir) if defined?(@movie_dir)
  end

  def with_fake_movie_tmdb(data)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| data } }
    TheMovieDb::Movie.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Movie.singleton_class.remove_method(:new)
  end

  test 'verifies digest and marks session as verified' do
    @movie_dir = Dir.mktmpdir('movie_dest_')
    create(:config_video, movie_dir: @movie_dir, tv_dir: '/tmp')

    content = 'movie file content for digest test'
    uid = 'uid-digest-verify'
    setup_tus_upload(uid:, content:)
    expected_digest = Base64.strict_encode64(Digest::SHA256.digest(content))

    movie_tmdb = {
      'title' => 'Test Movie',
      'release_date' => '2024-01-01',
      'poster_path' => '/test.jpg'
    }

    with_fake_movie_tmdb(movie_tmdb) do
      PromoteUploadJob.perform_now(
        upload_id: uid,
        tmdb_id: 123,
        filename: nil,
        media_type: 'movie',
        season_number: nil,
        episode_number: nil,
        client_digest: expected_digest
      )

      session = TusUploadSession.find(uid)
      assert_equal 'verified', session.verification_status
      assert_equal expected_digest, session.server_digest
      assert session.finalized
    end
  end

  test 'fails verification on mismatched digest and does not finalize' do
    @movie_dir = Dir.mktmpdir('movie_dest_')
    create(:config_video, movie_dir: @movie_dir, tv_dir: '/tmp')

    content = 'movie file content for digest test'
    uid = 'uid-digest-fail'
    setup_tus_upload(uid:, content:)
    wrong_digest = Base64.strict_encode64(Digest::SHA256.digest('wrong content'))

    movie_tmdb = {
      'title' => 'Test Movie',
      'release_date' => '2024-01-01',
      'poster_path' => '/test.jpg'
    }

    with_fake_movie_tmdb(movie_tmdb) do
      PromoteUploadJob.perform_now(
        upload_id: uid,
        tmdb_id: 123,
        filename: nil,
        media_type: 'movie',
        season_number: nil,
        episode_number: nil,
        client_digest: wrong_digest
      )

      session = TusUploadSession.find(uid)
      assert_equal 'verification_failed', session.verification_status
      assert_not session.finalized
    end
  end

  test 'stores client_digest on the session before verification' do
    @movie_dir = Dir.mktmpdir('movie_dest_')
    create(:config_video, movie_dir: @movie_dir, tv_dir: '/tmp')

    content = 'movie file content for digest test'
    uid = 'uid-digest-store'
    setup_tus_upload(uid:, content:)
    expected_digest = Base64.strict_encode64(Digest::SHA256.digest(content))

    movie_tmdb = {
      'title' => 'Test Movie',
      'release_date' => '2024-01-01',
      'poster_path' => '/test.jpg'
    }

    with_fake_movie_tmdb(movie_tmdb) do
      PromoteUploadJob.perform_now(
        upload_id: uid,
        tmdb_id: 123,
        filename: nil,
        media_type: 'movie',
        season_number: nil,
        episode_number: nil,
        client_digest: expected_digest
      )

      session = TusUploadSession.find(uid)
      assert_equal expected_digest, session.client_digest
    end
  end
end
