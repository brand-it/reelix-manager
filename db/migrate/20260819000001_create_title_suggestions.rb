# frozen_string_literal: true

#
# Creates the FTS5 title index used for client-side title autocomplete.
# Populated weekly by TitleSuggestionsRefreshJob from IMDb's title.basics dataset;
# the migration only creates the (empty) table.
#
class CreateTitleSuggestions < ActiveRecord::Migration[8.1]
  def change
    enable_extension 'fts5'
    create_virtual_table :title_suggestions, :fts5, [
      'title', 'original_title', 'tconst UNINDEXED',
      'media_type UNINDEXED', 'start_year UNINDEXED', 'end_year UNINDEXED',
      "prefix='3 6'"
    ]
  end
end
