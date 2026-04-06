class Config
  class Serializer
    # @rbs @data: ::Hash[String | Symbol, untyped]

    #: (String? json) -> Config::Serializer
    def self.load(json)
      data = json.present? ? JSON.parse(json) : {} #: ::Hash[String | Symbol, untyped]
      new(data.with_indifferent_access)
    end

    #: (?::Hash[String | Symbol, untyped] data) -> void
    def initialize(data = {}.with_indifferent_access) # steep:ignore UnannotatedEmptyCollection
      @data = data #: ::Hash[String | Symbol, untyped]
    end

    #: (String | Symbol key) -> untyped
    def [](key)
      @data[key]
    end

    #: (String | Symbol key, untyped value) -> untyped
    def []=(key, value)
      @data[key] = value
    end

    #: (String | Symbol key) -> bool
    def key?(key)
      @data.key?(key)
    end

    # Used by Setting#contains_key? to introspect the underlying hash.
    #: () -> ::Hash[String | Symbol, untyped]
    def marshal_dump
      @data
    end

    #: () -> ::Hash[String | Symbol, untyped]
    def to_h
      @data.to_h
    end
  end
end
