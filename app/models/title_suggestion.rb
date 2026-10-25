# frozen_string_literal: true

#
# A row in the FTS5 title index used for client-side autocomplete.
#
# Populated weekly by TitleSuggestionsRefreshJob from IMDb's title.basics
# dataset. Rows carry local metadata only — no TMDB IDs; clients resolve
# those themselves after the user picks a suggestion.
#
class TitleSuggestion < ApplicationRecord
  self.primary_key = nil

  MIN_TOKEN_LENGTH = 3
  MAX_RESULTS = 20

  # Runs a prefix search over the title index.
  #
  # Only tokens of at least MIN_TOKEN_LENGTH characters are used (the FTS5
  # prefix index is bounded, so shorter prefixes would force a full scan);
  # a query with no such token returns []. Results are ordered by bm25
  # relevance. start_year/end_year come back as strings ('' when unknown).
  #: (String, ?limit: Integer) -> ::Array[TitleSuggestion]
  def self.search(query, limit: MAX_RESULTS)
    tokens = query.to_s.strip.split(/\s+/).filter { |t| t.length >= MIN_TOKEN_LENGTH }
    return [] if tokens.empty?

    where('title_suggestions MATCH ?', build_match_expression(tokens))
      .where.not(title: '')
      .order(Arel.sql('bm25(title_suggestions)'))
      .limit(limit)
      .to_a
  end

  # Builds the FTS5 MATCH expression from whitespace tokens.
  #
  # This is the only place raw user input reaches SQL: each token is wrapped
  # in double quotes (internal double quotes doubled), with a trailing *
  # appended outside the quotes so the match is a prefix. Tokens longer than
  # 30 chars are truncated (FTS5 prefix limit is 32 chars per token), and at
  # most 10 tokens are used.
  #: (Array[String]) -> String
  def self.build_match_expression(tokens)
    tokens.first(10).map do |token|
      quoted = token[0..29].gsub('"', '""')
      "\"#{quoted}\"*"
    end.join(' ')
  end
end
