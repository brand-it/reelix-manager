# frozen_string_literal: true

require 'test_helper'

class TitleSuggestionsQueryTest < ActiveSupport::TestCase
  TITLE_SUGGESTIONS_QUERY = <<~GQL
    query TitleSuggestions($query: String!, $mediaType: String, $limit: Int) {
      titleSuggestions(query: $query, mediaType: $mediaType, limit: $limit) {
        title
        originalTitle
        tconst
        mediaType
        startYear
        endYear
      }
    }
  GQL

  setup do
    seed_suggestions(
      ['Inception', 'Inception', 'tt0468580', 'movie', '2010', ''],
      ['Breaking Bad', 'Breaking Bad', 'tt0903747', 'tv', '2008', '2013'],
      ['Alpha One', 'Alpha One', 'tt9000001', 'movie', '2024', ''],
      ['Alpha Two', 'Alpha Two', 'tt9000002', 'movie', '2024', ''],
      ['Alpha Three', 'Alpha Three', 'tt9000003', 'movie', '2024', '']
    )
  end

  # -- Helpers ---------------------------------------------------------------

  def seed_suggestions(*rows)
    stmt = TitleSuggestion.connection.raw_connection.prepare('INSERT INTO title_suggestions VALUES(?,?,?,?,?,?)')
    rows.each { |r| stmt.execute(*r) }
  end

  # Returns a GraphQL context hash with a fake Doorkeeper token holding the given scopes.
  def graphql_context(scopes: 'search')
    fake_token = Object.new.tap do |t|
      scope_list = scopes.split
      t.define_singleton_method(:includes_scope?) { |s| scope_list.include?(s.to_s) }
    end
    { doorkeeper_token: fake_token }
  end

  def suggestions(variables)
    result = ReelixManagerSchema.execute(TITLE_SUGGESTIONS_QUERY, variables:,
                                                                  context: graphql_context)
    assert_nil result['errors'], result['errors'].inspect
    result.dig('data', 'titleSuggestions')
  end

  # -- Tests -----------------------------------------------------------------

  test 'search-scope token gets results' do
    data = suggestions(query: 'inc')

    assert_equal 1, data.size
    assert_equal 'Inception',   data.first['title']
    assert_equal 'movie',       data.first['mediaType']
    assert_equal '2010',        data.first['startYear']
    assert_equal 'tt0468580',   data.first['tconst']
  end

  test 'token without search scope is forbidden' do
    result = ReelixManagerSchema.execute(TITLE_SUGGESTIONS_QUERY, variables: { query: 'inc' },
                                                                  context: graphql_context(scopes: 'upload'))

    assert result['errors'], 'expected an error'
    assert_includes result['errors'].first['message'], 'Forbidden: search scope required'
  end

  test 'mediaType filter restricts results' do
    tv = suggestions(query: 'bad', mediaType: 'tv')
    movies = suggestions(query: 'bad', mediaType: 'movie')

    assert_equal(['Breaking Bad'], tv.map { |s| s['title'] })
    assert_empty movies
  end

  test 'empty query returns an empty list, not an error' do
    assert_empty suggestions(query: '')
  end

  test 'limit is honored' do
    data = suggestions(query: 'alpha', limit: 2)

    assert_equal 2, data.size
  end
end
