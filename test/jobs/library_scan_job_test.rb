# frozen_string_literal: true

require "test_helper"
require "tmpdir"

class LibraryScanJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  setup do
    VideoBlob.delete_all
    @movie_dir = Dir.mktmpdir("scan_job_movies")
    @tv_dir    = Dir.mktmpdir("scan_job_tv")
    @config    = Config::Video.new
    @config.settings = {
      movie_path:     @movie_dir,
      tv_path:        @tv_dir,
      tmdb_api_key:   "test_key_123",
      processed_path: @movie_dir
    }
    @config.save!(validate: false)
  end

  teardown do
    FileUtils.remove_entry(@movie_dir)
    FileUtils.remove_entry(@tv_dir)
    VideoBlob.delete_all
    Config::Video.delete_all
  end

  test "runs without error on empty library" do
    assert_nothing_raised { LibraryScanJob.perform_now }
  end

  test "enqueues TmdbMatcherJob for newly discovered file" do
    add_mkv(@movie_dir, "Inception (2010)", "Inception (2010).mkv")

    assert_enqueued_jobs(1, only: TmdbMatcherJob) do
      LibraryScanJob.perform_now
    end
  end

  test "does not enqueue TmdbMatcherJob when all blobs already have a tmdb_id" do
    add_mkv(@movie_dir, "Inception (2010)", "Inception (2010).mkv")

    # First run — creates the blob
    LibraryScanJob.perform_now
    VideoBlob.update_all(tmdb_id: 27_205)

    # Second run — blob already has tmdb_id
    assert_no_enqueued_jobs(only: TmdbMatcherJob) do
      LibraryScanJob.perform_now
    end
  end

  private

  def add_mkv(base_dir, movie_dir, filename)
    dir = File.join(base_dir, movie_dir)
    FileUtils.mkdir_p(dir)
    FileUtils.touch(File.join(dir, filename))
  end
end
