class Config
  class Serializer
    def initialize(record, attribute_definitions, data)
      @record = record
      @attribute_definitions = attribute_definitions
      @data = data.with_indifferent_access
    end

    def [](key)
      key_s = key.to_s
      if @data.key?(key_s)
        @data[key_s]
      elsif @attribute_definitions.key?(key_s)
        resolve_default(@attribute_definitions[key_s][:default])
      end
    end

    def []=(key, value)
      @data[key.to_s] = value
    end

    def to_h
      @attribute_definitions.keys.each_with_object({}) do |key, hash|
        hash[key] = self[key]
      end
    end

    def to_json(*_args)
      to_h.to_json
    end

    def method_missing(name, *args, &block)
      key = name.to_s.delete_suffix("=")
      if @attribute_definitions.key?(key)
        name.to_s.end_with?("=") ? (self[key] = args.first) : self[key]
      else
        super
      end
    end

    def respond_to_missing?(name, include_private = false)
      key = name.to_s.delete_suffix("=")
      @attribute_definitions.key?(key) || super
    end

    private

    def resolve_default(default)
      default.respond_to?(:call) ? default.call : default
    end
  end
end
