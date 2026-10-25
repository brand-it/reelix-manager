# frozen_string_literal: true

module Imdb
  # Streams IMDb's title.basics dataset (https://datasets.imdb.com) for the
  # title suggestion index.
  #
  # No auth, no API key: the dataset is a public weekly TSV gzipped download.
  # Rows are filtered down to movies and TV series-like entries; everything
  # else (shorts, video, episodes, video games, adult, blank titles) is
  # dropped.
  class Base
    HOST = 'https://datasets.imdbws.com'
    BASE = 'title.basics.tsv.gz'
    KEPT_TYPES = %w[movie tvSeries tvMiniSeries tvSpecial tvMovie tvShort].freeze

    # Yields [tconst, media_type, title, original_title, start_year, end_year];
    # start_year/end_year are nil when the dataset says \\N.
    #
    # Downloads the gzipped dataset into a temp file, then streams decompressed
    # lines — the full 3.6 GB dataset is never held in memory.
    #: () -> ::Enumerator[::Array[::String?]]
    def self.rows
      Enumerator.new do |yielder|
        tmp = Tempfile.new(['title_basics', '.gz'])
        begin
          download(tmp)
          tmp.flush
          path = tmp.path || raise("Tempfile has no path: #{tmp.inspect}")
          Zlib::GzipReader.open(path) do |gz|
            gz.each_line do |line|
              f = line.chomp.split("\t", -1)
              next unless f.size == 9
              next unless KEPT_TYPES.include?(f[1])
              next if f[2].strip.empty?

              yielder.yield(
                f[0],
                f[1] == 'movie' ? 'movie' : 'tv',
                f[2],
                f[3],
                na(f[5]),
                na(f[6])
              )
            end
          end
        ensure
          tmp.close!
        end
      end
    end

    # Downloads the gzipped dataset and writes it to +dest+ (a Tempfile opened
    # for writing). Raises on any non-2xx response.
    # : (Tempfile) -> void
    def self.download(dest)
      response = Faraday.new(url: HOST).get(BASE)
      raise "IMDb dataset download failed: HTTP #{response.status}" unless response.success?

      dest.binmode.write(response.body)
    end

    # The dataset marks missing values with \\N; map them to nil.
    #: (String) -> String?
    def self.na(value)
      value == '\\N' ? nil : value
    end
  end
end
