# frozen_string_literal: true

module Types
  class GenreType < Types::BaseObject
    description 'A TMDB genre (shared by movies and TV shows)'

    field :id, Integer, null: false
    field :name, String, null: false

    #: () -> Integer
    def id   = object['id']

    #: () -> String
    def name = object['name'] || ''
  end
end
