# frozen_string_literal: true

require 'test_helper'

module TitleSuggestions
  class RefreshServiceTest < ActiveSupport::TestCase
    # -- Helpers ---------------------------------------------------------------

    def seed_suggestions(*rows)
      stmt = TitleSuggestion.connection.raw_connection.prepare('INSERT INTO title_suggestions VALUES(?,?,?,?,?,?)')
      rows.each { |r| stmt.execute(*r) }
    end

    def fetch_titles
      TitleSuggestion.connection.raw_connection
                     .execute('SELECT title FROM title_suggestions')
                     .flat_map(&:values)
    end

    def fetch_row(title_token)
      row = TitleSuggestion.connection.raw_connection
                           .execute('SELECT title, original_title, tconst, media_type, start_year, end_year ' \
                                    'FROM title_suggestions WHERE title_suggestions MATCH ?',
                                    ["\"#{title_token}\"*"])
                           .first
      row.values_at('title', 'original_title', 'tconst', 'media_type', 'start_year', 'end_year')
    end

    # Stubs Imdb::Base.rows so no network access occurs. Captures the original
    # method and restores it after each test (define_singleton_method overwrites
    # in place, so a bare remove_method would destroy the original).
    def with_fake_rows(enumerator)
      orig_rows = Imdb::Base.method(:rows)
      fake = -> { enumerator }
      Imdb::Base.define_singleton_method(:rows, &fake)
      yield
    ensure
      Imdb::Base.define_singleton_method(:rows, &orig_rows.to_proc)
    end

    # -- Tests -----------------------------------------------------------------

    test 'rebuilds the table from fresh rows and returns kept count' do
      seed_suggestions(['OldTitle', '', 'tt0000000', 'movie', '1990', ''])

      rows = Enumerator.new do |y|
        y.yield(['tt0000001', 'movie', 'Inception', 'Inception', '2010', nil])
        y.yield(['tt0000002', 'tv', 'Breaking Bad', 'Breaking Bad', '2008', '2013'])
      end

      with_fake_rows(rows) do
        result = TitleSuggestions::RefreshService.call

        assert_equal 2, result[:kept]
        refute_includes fetch_titles, 'OldTitle'

        inception = fetch_row('Inception')
        assert_equal ['Inception', 'Inception', 'tt0000001', 'movie', '2010', ''], inception

        bad = fetch_row('Bad')
        assert_equal ['Breaking Bad', 'Breaking Bad', 'tt0000002', 'tv', '2008', '2013'], bad
      end
    end

    test 'mid-stream parse failure leaves the existing table intact' do
      seed_suggestions(['OldTitle', '', 'tt0000000', 'movie', '1990', ''])

      rows = Enumerator.new do |y|
        y.yield(['tt0000001', 'movie', 'Inception', 'Inception', '2010', nil])
        raise 'mid-stream failure'
      end

      with_fake_rows(rows) do
        assert_raises(RuntimeError, 'mid-stream failure') { TitleSuggestions::RefreshService.call }
      end

      assert_includes fetch_titles, 'OldTitle'
      refute_includes fetch_titles, 'Inception'
    end

    test 'empty dataset still leaves a queryable table' do
      seed_suggestions(['OldTitle', '', 'tt0000000', 'movie', '1990', ''])
      rows = [].each # empty enumerator
      with_fake_rows(rows) do
        result = TitleSuggestions::RefreshService.call

        assert_equal 0, result[:kept]
        refute_includes fetch_titles, 'OldTitle'
        assert_equal [], fetch_titles
      end
    end
  end
end
