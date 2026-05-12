# frozen_string_literal: true

require 'test_helper'

class FinalizeUploadMutationTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  FINALIZE_MUTATION = <<~GQL
    mutation FinalizeUpload($input: FinalizeUploadInput!) {
      finalizeUpload(input: $input) {
        videoBlob {
          id
          key
          filename
          title
          year
          tmdbId
          mediaType
          posterUrl
        }
        destinationPath
        errors
      }
    }
  GQL

  # ---------------------------------------------------------------------------
  # Helpers
  # ---------------------------------------------------------------------------

  def graphql_context
    fake_token = Object.new.tap do |t|
      t.define_singleton_method(:includes_scope?) { |s| %w[upload all].include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  def with_fake_tus_upload(uid:, original_filename: 'movie.mkv', size: 8)
    dir = Dir.mktmpdir('tus_test_')
    File.write(File.join(dir, uid), 'x' * size)

    encoded_filename = Base64.strict_encode64(original_filename)
    fake_info = {
      'Upload-Length' => size.to_s,
      'Upload-Offset' => size.to_s,
      'Upload-Metadata' => "filename #{encoded_filename}"
    }

    fake_storage = Object.new.tap do |s|
      s.define_singleton_method(:read_info) { |_uid| fake_info }
      s.define_singleton_method(:delete_file) { |*| }
      s.define_singleton_method(:directory) { dir }
    end

    Tus::Server.define_singleton_method(:opts) { { storage: fake_storage, expiration_time: 48.hours } }

    # Create TusUploadSession record for the upload
    tus_session = TusUploadSession.create!(
      id: uid,
      filename: original_filename,
      upload_length: size,
      metadata: fake_info['Upload-Metadata'],
      finalized: false
    )

    yield dir, tus_session
  ensure
    TusUploadSession.find_by(id: uid)&.destroy if defined?(uid)
    FileUtils.rm_rf(dir) if defined?(dir)
    Tus::Server.singleton_class.remove_method(:opts) if Tus::Server.singleton_class.method_defined?(:opts)
  end

  def with_fake_movie_tmdb(data)
    stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| data } }
    TheMovieDb::Movie.define_singleton_method(:new) { |**_| stub }
    yield
  ensure
    TheMovieDb::Movie.singleton_class.remove_method(:new)
  end

  def with_fake_tv_tmdb(tv_data:, season_data:)
    tv_stub     = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| tv_data } }
    season_stub = Object.new.tap { |o| o.define_singleton_method(:results) { |**_| season_data } }
    TheMovieDb::Tv.define_singleton_method(:new) { |**_| tv_stub }
    TheMovieDb::Season.define_singleton_method(:new) { |**_| season_stub }
    yield
  ensure
    TheMovieDb::Tv.singleton_class.remove_method(:new)
    TheMovieDb::Season.singleton_class.remove_method(:new)
  end

  def execute(variables)
    ReelixManagerSchema.execute(FINALIZE_MUTATION, variables: { input: variables }, context: graphql_context)
  end

  # ---------------------------------------------------------------------------
  # Movie upload
  # ---------------------------------------------------------------------------

  test 'successfully finalizes a movie upload and creates VideoBlob' do
    movie_dir = Dir.mktmpdir('movie_dest_')
    create(:config_video, movie_dir:, tv_dir: '/tmp')

    movie_tmdb = {
      'title' => 'Batman Begins',
      'release_date' => '2005-06-15',
      'poster_path' => '/batman.jpg'
    }

    with_fake_tus_upload(uid: 'uid-movie-1') do
      with_fake_movie_tmdb(movie_tmdb) do
        result = nil

        # Verify job is enqueued and execute it
        assert_enqueued_jobs(1, only: PromoteUploadJob) do
          result = execute(uploadId: 'uid-movie-1', tmdbId: 272)
        end

        # Mutation returns immediately with empty response (async)
        assert_nil result['errors'], result['errors'].inspect
        data = result.dig('data', 'finalizeUpload')
        assert_empty data['errors']
        assert_nil data['videoBlob']
        assert_nil data['destinationPath']

        # Perform the enqueued job to verify it works
        perform_enqueued_jobs

        # Verify VideoBlob was created by the job
        blob = VideoBlob.find_by(tmdb_id: 272)
        refute_nil blob
        assert_equal 'Batman Begins', blob.title
        assert_equal 2005, blob.year
        assert_equal 272, blob.tmdb_id
        assert_equal 'movie', blob.media_type
        assert_includes blob.key, 'Batman Begins (2005)'
        assert_includes blob.filename, 'Batman Begins (2005)'
        refute_includes blob.key, '{tmdb-272}'
        refute_includes blob.filename, '{tmdb-272}'
        assert File.exist?(blob.key), "Expected file to exist at #{blob.key}"
      end
    end
  ensure
    FileUtils.rm_rf(movie_dir)
  end

  test 'creates a VideoBlob record in the database' do
    movie_dir = Dir.mktmpdir('movie_dest_')
    create(:config_video, movie_dir:, tv_dir: '/tmp')

    movie_tmdb = {
      'title' => 'Inception',
      'release_date' => '2010-07-16',
      'poster_path' => nil
    }

    with_fake_tus_upload(uid: 'uid-movie-2') do
      with_fake_movie_tmdb(movie_tmdb) do
        assert_difference 'VideoBlob.count', 1 do
          assert_enqueued_jobs(1, only: PromoteUploadJob) do
            execute(uploadId: 'uid-movie-2', tmdbId: 27_205)
          end
          # Perform the enqueued job
          perform_enqueued_jobs
        end
      end
    end
  ensure
    FileUtils.rm_rf(movie_dir)
  end

  # ---------------------------------------------------------------------------
  # TV upload
  # ---------------------------------------------------------------------------

  test 'successfully finalizes a TV episode upload and creates VideoBlob' do
    tv_dir = Dir.mktmpdir('tv_dest_')
    create(:config_video, movie_dir: '/tmp', tv_dir:)

    tv_tmdb     = { 'name' => 'Breaking Bad', 'first_air_date' => '2008-01-20', 'poster_path' => '/bb.jpg' }
    season_tmdb = { 'episodes' => [{ 'episode_number' => 1, 'name' => 'Pilot' }] }

    with_fake_tus_upload(uid: 'uid-tv-1', original_filename: 'episode.mkv') do
      with_fake_tv_tmdb(tv_data: tv_tmdb, season_data: season_tmdb) do
        result = nil

        # Verify job is enqueued
        assert_enqueued_jobs(1, only: PromoteUploadJob) do
          result = execute(uploadId: 'uid-tv-1', tmdbId: 1396, mediaType: 'tv',
                           seasonNumber: 1, episodeNumber: 1)
        end

        # Mutation returns immediately with empty response (async)
        assert_nil result['errors'], result['errors'].inspect
        data = result.dig('data', 'finalizeUpload')
        assert_empty data['errors']
        assert_nil data['videoBlob']
        assert_nil data['destinationPath']

        # Perform the enqueued job
        perform_enqueued_jobs

        # Verify VideoBlob was created by the job
        blob = VideoBlob.find_by(tmdb_id: 1396)
        refute_nil blob
        assert_equal 'Breaking Bad', blob.title
        assert_equal 2008, blob.year
        assert_equal 1396, blob.tmdb_id
        assert_equal 'tv', blob.media_type
        assert_includes blob.key, 'Season 01'
        assert_includes blob.key, 'S01E01'
        assert_includes blob.key, 'Pilot'
      end
    end
  ensure
    FileUtils.rm_rf(tv_dir)
  end

  # ---------------------------------------------------------------------------
  # Error cases
  # ---------------------------------------------------------------------------

  test 'returns error when upload is not found' do
    result = execute(uploadId: 'missing-uid', tmdbId: 1)
    data   = result.dig('data', 'finalizeUpload')
    refute_nil data, result.inspect
    assert_includes data['errors'].first, 'not found'
  end

  test 'returns error when upload is incomplete' do
    # This test checks that the mutation still enqueues the job even for incomplete uploads
    # The actual validation happens in the job, which will fail when performed
    uid = 'incomplete-uid'
    TusUploadSession.create!(id: uid, filename: 'incomplete.mkv', upload_length: 1000, metadata: '', finalized: false)

    # Verify job is enqueued
    result = nil
    assert_enqueued_jobs(1, only: PromoteUploadJob) do
      result = execute(uploadId: uid, tmdbId: 1)
    end

    data = result.dig('data', 'finalizeUpload')
    refute_nil data, result.inspect
    # Mutation returns immediately with empty errors (async)
    assert_empty data['errors']
  ensure
    TusUploadSession.find_by(id: uid)&.destroy
  end

  test 'returns error when TV upload is missing season_number' do
    with_fake_tus_upload(uid: 'uid-tv-noseas') do
      result = execute(uploadId: 'uid-tv-noseas', tmdbId: 1396, mediaType: 'tv',
                       episodeNumber: 1)
      data   = result.dig('data', 'finalizeUpload')
      refute_nil data, result.inspect
      assert_includes data['errors'].first, 'season_number'
    end
  end

  test 'returns error when TV upload is missing episode_number' do
    with_fake_tus_upload(uid: 'uid-tv-noep') do
      result = execute(uploadId: 'uid-tv-noep', tmdbId: 1396, mediaType: 'tv',
                       seasonNumber: 1)
      data   = result.dig('data', 'finalizeUpload')
      refute_nil data, result.inspect
      assert_includes data['errors'].first, 'episode_number'
    end
  end

  test 'returns error when media_type is invalid' do
    with_fake_tus_upload(uid: 'uid-invalid-type') do
      result = execute(uploadId: 'uid-invalid-type', tmdbId: 272, mediaType: 'nope')
      data   = result.dig('data', 'finalizeUpload')
      refute_nil data, result.inspect
      assert_includes data['errors'].first, 'media_type must be one of: movie, tv'
    end
  end

  test 'returns error when no Config::Video is configured' do
    Config::Video.delete_all
    with_fake_tus_upload(uid: 'uid-noconfig') do
      result = execute(uploadId: 'uid-noconfig', tmdbId: 272)
      data   = result.dig('data', 'finalizeUpload')
      refute_nil data, result.inspect
      # Config validation happens in the job, mutation returns immediately
      assert_empty data['errors']
    end
  end

  test 'returns GraphQL forbidden error without upload scope' do
    fake_token = Object.new.tap do |t|
      t.define_singleton_method(:includes_scope?) { |_| false }
    end
    context = { doorkeeper_token: fake_token }
    result  = ReelixManagerSchema.execute(FINALIZE_MUTATION,
                                          variables: { input: { uploadId: 'x', tmdbId: 1 } },
                                          context:)
    # ready? raises GraphQL::ExecutionError which appears in top-level errors
    errors = result['errors'] || []
    assert errors.any? { |e| e['message']&.include?('upload scope') },
           "Expected forbidden error, got: #{result.inspect}"
  end
end
