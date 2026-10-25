# frozen_string_literal: true

module Types
  # A local title candidate from the FTS5 index. Carries IMDb-derived
  # metadata only — no TMDB IDs; clients resolve those after the user
  # picks a suggestion.
  class TitleSuggestionType < Types::BaseObject
    field :title, String, null: false, description: 'Primary title as indexed locally.'
    field :original_title, String, null: true, description: 'Original-language title when different.'
    field :tconst, String, null: true, description: 'IMDb tconst (e.g. tt0272441).'
    field :media_type, String, null: false, description: "'movie' or 'tv'."
    field :start_year, String, null: true, description: 'Start year as stored; empty when unknown.'
    field :end_year, String, null: true, description: 'End year for series; empty when unknown.'
  end
end
