# frozen_string_literal: true

module Resolvers
  # Returns candidate titles from the local FTS5 index for client-side
  # autocomplete. Results carry local metadata only; the client resolves
  # TMDB IDs itself on selection.
  class TitleSuggestionsResolver < Resolvers::BaseResolver
    type [Types::TitleSuggestionType], null: false

    argument :query, String, required: true, description: 'Title fragment to match (prefix, multi-word OK).'
    argument :media_type, String, required: false, description: "Restrict to 'movie' or 'tv'."
    argument :limit, Integer, required: false, description: 'Max suggestions (default 20).'

    #: (query: String, ?media_type: String?, ?limit: Integer) -> ::Array[TitleSuggestion]
    def resolve(query:, media_type: nil, limit: nil)
      require_search!

      results = TitleSuggestion.search(query, limit: limit || TitleSuggestion::MAX_RESULTS)
      results.select! { |s| s.media_type == media_type } if media_type.present?
      results
    end
  end
end
