# frozen_string_literal: true

module Types
  class SearchResponseType < Types::BaseObject
    description 'Paginated response from a combined movie and TV show search'

    field :results, [Types::SearchResultType], null: false
    field :page, Integer, null: false
    field :total_pages, Integer, null: false
    field :total_results, Integer, null: false
  end
end
