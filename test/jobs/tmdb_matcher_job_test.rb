# frozen_string_literal: true

require "test_helper"

class TmdbMatcherJobTest < ActiveSupport::TestCase
  include ActiveJob::TestHelper

  # ---------------------------------------------------------------------------
  # Movie matching
  # ---------------------------------------------------------------------------

  test "sets tmdb_id on movie blob from TMDB search result" do
    blob = create(:video_blob, title: "Inception", year: 2010)

    stub_movie_search([ { "id" => 27_205, "release_date" => "2010-07-16", "title" => "Inception" } ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_equal 27_205, blob.reload.tmdb_id
  end

  test "prefers year-matching movie result" do
    blob = create(:video_blob, title: "The Thing", year: 1982)

    stub_movie_search([
      { "id" => 1, "release_date" => "2011-01-01", "title" => "The Thing" },
      { "id" => 2, "release_date" => "1982-06-25", "title" => "The Thing" }
    ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_equal 2, blob.reload.tmdb_id
  end

  test "falls back to first result when no year match" do
    blob = create(:video_blob, title: "Obscure Film", year: nil)

    stub_movie_search([ { "id" => 99, "release_date" => "2005-01-01", "title" => "Obscure Film" } ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_equal 99, blob.reload.tmdb_id
  end

  # ---------------------------------------------------------------------------
  # TV matching
  # ---------------------------------------------------------------------------

  test "sets tmdb_id on tv blob from TMDB search result" do
    blob = create(:video_blob, :tv, title: "Breaking Bad", year: 2008)

    stub_tv_search([ { "id" => 1396, "first_air_date" => "2008-01-20", "name" => "Breaking Bad" } ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_equal 1396, blob.reload.tmdb_id
  end

  # ---------------------------------------------------------------------------
  # Guards
  # ---------------------------------------------------------------------------

  test "skips blob that already has a tmdb_id" do
    blob = create(:video_blob, :with_tmdb_id)
    original_id = blob.tmdb_id

    TmdbMatcherJob.perform_now(blob.id)

    assert_equal original_id, blob.reload.tmdb_id
  end

  test "skips gracefully when blob no longer exists" do
    assert_nothing_raised { TmdbMatcherJob.perform_now(0) }
  end

  test "skips blob with blank title" do
    blob = create(:video_blob, title: nil)

    TmdbMatcherJob.perform_now(blob.id)

    assert_nil blob.reload.tmdb_id
  end

  # ---------------------------------------------------------------------------
  # Empty results
  # ---------------------------------------------------------------------------

  test "does not set tmdb_id when TMDB returns no results" do
    blob = create(:video_blob, title: "Unknown Movie")

    stub_movie_search([]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_nil blob.reload.tmdb_id
  end

  # ---------------------------------------------------------------------------
  # poster_url
  # ---------------------------------------------------------------------------

  test "sets poster_url when search result includes poster_path" do
    blob = create(:video_blob, title: "Inception", year: 2010)

    stub_movie_search([
      { "id" => 27_205, "release_date" => "2010-07-16", "poster_path" => "/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg" }
    ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_equal TheMovieDb::Image.poster_url("/qmDpIHrmpJINaRKAfWQfftjCdyi.jpg"), blob.reload.poster_url
  end

  test "leaves poster_url nil when search result has no poster_path" do
    blob = create(:video_blob, title: "Obscure Movie", year: 2020)

    stub_movie_search([
      { "id" => 999, "release_date" => "2020-01-01", "poster_path" => nil }
    ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_nil blob.reload.poster_url
  end

  test "leaves poster_url nil when search result has blank poster_path" do
    blob = create(:video_blob, title: "Silent Film", year: 2019)

    stub_movie_search([
      { "id" => 888, "release_date" => "2019-03-15", "poster_path" => "" }
    ]) do
      TmdbMatcherJob.perform_now(blob.id)
    end

    assert_nil blob.reload.poster_url
  end

  private

  def stub_movie_search(results)
    fake_client = Object.new
    fake_client.define_singleton_method(:results) { |**| { "results" => results } }
    TheMovieDb::Search::Movie.define_singleton_method(:new) { |**| fake_client }
    yield
  ensure
    TheMovieDb::Search::Movie.singleton_class.remove_method(:new)
  end

  def stub_tv_search(results)
    fake_client = Object.new
    fake_client.define_singleton_method(:results) { |**| { "results" => results } }
    TheMovieDb::Search::Tv.define_singleton_method(:new) { |**| fake_client }
    yield
  ensure
    TheMovieDb::Search::Tv.singleton_class.remove_method(:new)
  end
end
