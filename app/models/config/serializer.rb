class Config
  class Serializer
    def self.load(json)
      data = json.present? ? JSON.parse(json) : ({} #: ::Hash[untyped, untyped])
      new(data.with_indifferent_access)
    end

    def initialize(data = ({}.with_indifferent_access #: ::Hash[untyped, untyped]))
      @data = data
    end

    def [](key)
      @data[key]
    end

    def []=(key, value)
      @data[key] = value
    end

    def key?(key)
      @data.key?(key)
    end

    # Used by Setting#contains_key? to introspect the underlying hash.
    def marshal_dump
      @data
    end

    def to_h
      @data.to_h
    end
  end
end
