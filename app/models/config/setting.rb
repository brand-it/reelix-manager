class Config
  class Setting
    attr_reader :attributes

    def self.call(block)
      new.tap { |s| block.call(s) }
    end

    def initialize
      @attributes = {}
    end

    def attribute(name, default: nil)
      @attributes[name.to_s] = { default: default }
    end

    def load(record, raw)
      data = raw.present? ? JSON.parse(raw) : {}
      Serializer.new(record, attributes, data)
    end

    def dump(_record, serializer)
      serializer.to_json
    end
  end
end
