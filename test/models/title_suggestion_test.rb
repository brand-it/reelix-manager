# frozen_string_literal: true

require 'test_helper'

class TitleSuggestionTest < ActiveSupport::TestCase
  setup do
    seed_suggestions(
      ['Inception', 'Inception', 'tt0468580', 'movie', '2010', ''],
      ['Inception 2', 'Inception 2', 'tt0999999', 'movie', '2020', ''],
      ['Interstellar', 'Interstellar', 'tt0816692', 'movie', '2014', ''],
      ['Star Wars', 'Star Wars', 'tt0076759', 'movie', '1977', ''],
      ['Breaking Bad', 'Breaking Bad', 'tt0903747', 'tv', '2008', '2013'],
      ['Amelie', "Le Fabuleux Destin d'Amelie Poulain", 'tt0120689', 'movie', '2001', ''],
      ['La La Land', 'La La Land', 'tt2370387', 'movie', '2016', '']
    )
  end

  # -- Helpers ---------------------------------------------------------------

  def seed_suggestions(*rows)
    stmt = TitleSuggestion.connection.raw_connection.prepare('INSERT INTO title_suggestions VALUES(?,?,?,?,?,?)')
    rows.each { |r| stmt.execute(*r) }
  end

  # -- Tests -----------------------------------------------------------------

  test 'prefix search matches by title' do
    results = TitleSuggestion.search('inc')

    assert_includes results.map(&:title), 'Inception'
  end

  test 'multi-word prefix search matches' do
    results = TitleSuggestion.search('star w')

    assert_includes results.map(&:title), 'Star Wars'
  end

  test 'search matches the original_title column' do
    results = TitleSuggestion.search('fabuleux')

    assert_includes results.map(&:title), 'Amelie'
  end

  test 'longer tokens match across multi-word titles' do
    results = TitleSuggestion.search('land')

    assert_includes results.map(&:title), 'La La Land'
  end

  test 'closer match ranks above looser match' do
    results = TitleSuggestion.search('inception')

    assert_equal 'Inception', results.first.title
  end

  test 'attribute readers return stored strings' do
    result = TitleSuggestion.search('inc').first

    assert_equal 'Inception', result.title
    assert_equal 'movie',     result.media_type
    assert_equal '2010',      result.start_year
    assert_equal 'tt0468580', result.tconst
  end

  test 'queries with no token of at least 3 chars return empty' do
    assert_equal [], TitleSuggestion.search('in')
    assert_equal [], TitleSuggestion.search('ab cd')
    assert_equal [], TitleSuggestion.search('')
    assert_equal [], TitleSuggestion.search(nil)
  end

  test 'injection payloads return no results without raising' do
    assert_equal [], TitleSuggestion.search('x" OR 1=1')
    assert_equal [], TitleSuggestion.search('1=1')
    assert_equal [], TitleSuggestion.search('a"b')
  end

  test 'limit is honored' do
    results = TitleSuggestion.search('inception', limit: 1)

    assert_equal 1, results.size
    assert_equal 'Inception', results.first.title
  end

  test 'build_match_expression quotes and doubles embedded double quotes' do
    assert_equal '"a""b"*', TitleSuggestion.build_match_expression(['a"b'])
  end

  test 'build_match_expression appends prefix star outside the quotes' do
    assert_equal '"inc"*', TitleSuggestion.build_match_expression(['inc'])
  end

  test 'build_match_expression truncates tokens to 30 chars' do
    long = 'a' * 35

    assert_equal "\"#{'a' * 30}\"*", TitleSuggestion.build_match_expression([long])
  end

  test 'build_match_expression caps tokens at 10' do
    tokens = (0...15).map { |i| "tok#{i}x" }
    expression = TitleSuggestion.build_match_expression(tokens)

    assert_equal 10, expression.split.size
    assert_includes expression, '"tok0x"*'
    refute_includes expression, '"tok10x"*'
  end
end
