# frozen_string_literal: true

module Types
  class QueryType < Types::BaseObject
    include ScopeEnforceable

    field :node, Types::NodeType, null: true, description: "Fetches an object given its ID." do
      argument :id, ID, required: true, description: "ID of the object."
    end

    #: (id: String) -> ApplicationRecord?
    def node(id:)
      require_search!
      context.schema.object_from_id(id, context)
    end

    field :nodes, [ Types::NodeType, null: true ], null: true, description: "Fetches a list of objects given a list of IDs." do
      argument :ids, [ ID ], required: true, description: "IDs of the objects."
    end

    #: (ids: ::Array[String]) -> ::Array[ApplicationRecord?]
    def nodes(ids:)
      require_search!
      ids.map { |id| context.schema.object_from_id(id, context) }
    end

    # Add root-level fields here.
    # They will be entry points for queries on your schema.

    field :search_multi, resolver: Resolvers::SearchResolver,
      description: "Search for both movies and TV shows. Results are ranked by " \
                   "keyword relevance and popularity."

    field :movie, resolver: Resolvers::MovieResolver,
      description: "Fetch full movie details from TMDB by ID."

    field :tv, resolver: Resolvers::TvResolver,
      description: "Fetch full TV show details from TMDB by ID."

    field :season, resolver: Resolvers::SeasonResolver,
      description: "Fetch full season details (with episodes) from TMDB."
  end
end
