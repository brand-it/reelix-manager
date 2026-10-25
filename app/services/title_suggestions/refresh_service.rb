# frozen_string_literal: true

module TitleSuggestions
  # Shared FTS5 table definition for the title suggestion index.
  # Used by both the migration (initial creation) and the refresh service
  # (weekly drop-and-recreate) so the column list cannot drift.
  TABLE_DEFS = [
    'title', 'original_title', 'tconst UNINDEXED',
    'media_type UNINDEXED', 'start_year UNINDEXED', 'end_year UNINDEXED',
    "prefix='3 6'"
  ].freeze

  # Rebuilds the FTS5 title index from a fresh IMDb download.
  #
  # Download and parsing run outside the transaction so a network failure
  # leaves the existing index untouched. The drop, recreate, and batched
  # inserts happen in one transaction: readers see either the old complete
  # table or the new one, never a partial rebuild. Returns { kept: N }.
  class RefreshService < ApplicationService
    BATCH_SIZE = 5000

    #: () -> ::Hash[Symbol, Integer]
    def call
      rows = Imdb::Base.rows
      conn = ActiveRecord::Base.connection

      kept = 0
      batch = []
      conn.transaction do
        conn.drop_virtual_table(:title_suggestions, :fts5, TABLE_DEFS)
        conn.create_virtual_table(:title_suggestions, :fts5, TABLE_DEFS)
        stmt = conn.raw_connection.prepare('INSERT INTO title_suggestions VALUES(?,?,?,?,?,?)')
        rows.each do |tconst, media_type, title, original_title, start_year, end_year|
          batch << [title, original_title, tconst, media_type, start_year.to_s, end_year.to_s]
          if ((kept += 1) % BATCH_SIZE).zero?
            batch.each { |r| stmt.execute(*r) }
            batch.clear
          end
        end
        batch.each { |r| stmt.execute(*r) }
        conn.execute("INSERT INTO title_suggestions(title_suggestions) VALUES('rebuild')")
      end
      { kept: }
    end
  end
end
