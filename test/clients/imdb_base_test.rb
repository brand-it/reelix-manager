# frozen_string_literal: true

require 'test_helper'

class ImdbBaseTest < ActiveSupport::TestCase
  # title.basics.tsv.gz has 9 columns:
  # tconst, titleType, primaryTitle, originalTitle, isOriginalTitle,
  # startYear, endYear, runtimeMinutes, genres

  def self.tsv_row(tconst, type, title, original, start_year, end_year)
    [tconst, type, title, original, '0', start_year, end_year, '\\N', ''].join("\t")
  end

  TSV_CONTENT = [
    'tconst\ttitleType\tprimaryTitle\toriginalTitle\tisOriginalTitle\tstartYear\tendYear\truntimeMinutes\tgenres',
    tsv_row('tt0000001', 'movie', 'The Movie', 'The Movie', '1995', '\\N'),
    tsv_row('tt0000002', 'tvSeries', 'The Show', 'The Show', '1999', '2004'),
    tsv_row('tt0000003', 'tvMiniSeries', 'Mini Series', 'Mini', '2010', '\\N'),
    tsv_row('tt0000004', 'tvSpecial', 'Special One', 'Spécial', '\\N', '\\N'),
    tsv_row('tt0000005', 'tvMovie', 'Movie Special', 'MS', '2005', '\\N'),
    tsv_row('tt0000006', 'tvShort', 'Short TV', 'ST', '2006', '\\N'),
    tsv_row('tt0000007', 'tvEpisode', 'An Episode', 'An Episode', '2001', '\\N'),
    tsv_row('tt0000008', 'short', 'A Short', 'Short', '2002', '\\N'),
    tsv_row('tt0000009', 'video', 'A Video', 'Vid', '2003', '\\N'),
    tsv_row('tt0000010', 'videoGame', 'A Game', 'Game', '2004', '\\N'),
    tsv_row('tt0000011', 'movie', '', 'Blank Movie', '2006', '\\N'),
    'tt0000012\tbroken\tRow', # wrong column count
    tsv_row('tt0000013', 'movie', 'Last Movie', 'Last', '\\N', '\\N')
  ].join("\n")

  # -- Helpers ---------------------------------------------------------------

  def gzip_bytes(content)
    out = StringIO.new
    gz = Zlib::GzipWriter.new(out)
    gz.write(content)
    gz.close
    out.string
  end

  # Stubs Imdb::Base.download so rows reads a gzipped in-memory fixture instead
  # of hitting the network. Captures the original method and restores it after
  # each test — define_singleton_method overwrites in place, so a bare
  # remove_method would destroy the original.
  def with_fixture_download
    orig_download = Imdb::Base.method(:download)
    data = gzip_bytes(TSV_CONTENT)
    stub = ->(dest) { dest.write(data) }
    Imdb::Base.define_singleton_method(:download) { |dest| stub.call(dest) }
    yield
  ensure
    Imdb::Base.define_singleton_method(:download, &orig_download.to_proc)
  end

  # -- Tests -----------------------------------------------------------------

  test 'rows keeps only the supported title types' do
    with_fixture_download do
      rows = Imdb::Base.rows.to_a
      types = rows.map { |r| r[1] }.tally

      assert_equal 2, types['movie']
      assert_equal 5, types['tv']
      # Dropped: tvEpisode, short, video, videoGame, header row, blank title.
      assert_equal 7, rows.size
    end
  end

  test 'rows maps movie to movie and TV types to tv' do
    with_fixture_download do
      rows = Imdb::Base.rows.to_a

      movie = rows.find { |r| r[0] == 'tt0000001' }
      tv    = rows.find { |r| r[0] == 'tt0000002' }

      assert_equal 'movie', movie[1]
      assert_equal 'tv',    tv[1]
    end
  end

  test 'rows converts missing years to nil and keeps present ones' do
    with_fixture_download do
      rows = Imdb::Base.rows.to_a

      movie   = rows.find { |r| r.first == 'tt0000001' }
      special = rows.find { |r| r.first == 'tt0000004' }
      series  = rows.find { |r| r.first == 'tt0000002' }
      last    = rows.find { |r| r.first == 'tt0000013' }
      assert_equal '1995',  movie[4]
      assert_nil            movie[5]
      assert_nil           special[4]
      assert_nil           special[5]
      assert_equal '1999', series[4]
      assert_equal '2004', series[5]
      assert_nil            last[4]
      assert_nil            last[5]
    end
  end

  test 'rows yields title and original title' do
    with_fixture_download do
      row = Imdb::Base.rows.to_a.find { |r| r.first == 'tt0000002' }

      assert_equal 'The Show', row[2]
      assert_equal 'The Show', row[3]
    end
  end

  test 'rows skips malformed rows instead of raising' do
    with_fixture_download do
      # The 3-column row (tt0000012) must not appear and must not raise.
      rows = Imdb::Base.rows.to_a

      refute_includes rows.map(&:first), 'tt0000012'
    end
  end
end
