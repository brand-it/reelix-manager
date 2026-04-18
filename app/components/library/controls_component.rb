# frozen_string_literal: true

module Library
  class ControlsComponent < ViewComponent::Base
    #: (query: String, media_type_filter: String) -> void
    def initialize(query:, media_type_filter:)
      @query = query
      @media_type_filter = media_type_filter
    end

    #: String
    attr_reader :query

    #: String
    attr_reader :media_type_filter

    #: () -> Array[Array[String]]
    def media_types
      [
        ['', 'All'],
        ['movie', 'Movies'],
        ['tv', 'TV Shows']
      ]
    end
  end
end
