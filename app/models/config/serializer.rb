class Config
  class Serializer
    # @rbs @data: ::Hash[untyped, untyped]

    #: (String? json) -> Config::Serializer
    def self.load(json)
      data = json.present? ? JSON.parse(json) : {} #: ::Hash[untyped, untyped]
      new(data.with_indifferent_access)
    end

    #: (?::Hash[untyped, untyped] data) -> void
    def initialize(data = {}.with_indifferent_access) # steep:ignore UnannotatedEmptyCollection
      @data = data #: ::Hash[untyped, untyped]
    end

    #: (untyped key) -> untyped
    def [](key)
      @data[key]
    end

    #: (untyped key, untyped value) -> untyped
    def []=(key, value)
      @data[key] = value
    end

    #: (untyped key) -> bool
    def key?(key)
      @data.key?(key)
    end

    # Used by Setting#contains_key? to introspect the underlying hash.
    #: () -> ::Hash[untyped, untyped]
    def marshal_dump
      @data
    end

    #: () -> ::Hash[untyped, untyped]
    def to_h
      @data.to_h
    end
  end
end
