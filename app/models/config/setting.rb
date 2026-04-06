class Config
  class Setting
    include SimplyEncrypt

    # @rbs @attributes: ::Hash[Symbol, Config::Setting::Option]

    Option = Struct.new(:default, :encrypted?)

    class << self
      #: (Proc block) -> Config::Setting
      def call(block)
        new.tap(&block) # steep:ignore BlockTypeMismatch
      end
    end

    #: (Config item, String? json) -> Config::Serializer
    def load(item, json)
      load_attributes(item, Config::Serializer.load(json))
    end

    #: (Config item, ::Hash[String | Symbol, untyped] object) -> String
    def dump(item, object)
      JSON.dump dump_attributes(item, object).to_h
    end

    #: (Symbol | String name, ?default: Proc, ?encrypted: bool) -> void
    def attribute(name, default: -> { }, encrypted: false)
      attributes[name.to_sym] = Option.new(default, encrypted)
    end

    #: () -> ::Hash[Symbol, Config::Setting::Option]
    def attributes
      @attributes ||= {} #: ::Hash[Symbol, Config::Setting::Option]
    end

    private

    #: (Config item, Config::Serializer object) -> Config::Serializer
    def load_attributes(item, object)
      attributes.each do |name, option|
        object[name] = decrypt(object[name], object[:"#{name}_iv"]) if option.encrypted?
        object[name] = instance_exec_default(item, option) unless contains_key?(object, name)
      end
      object
    end

    #: (Config item, ::Hash[String | Symbol, untyped] object) -> ::Hash[String | Symbol, untyped]
    def dump_attributes(item, object)
      attributes.each do |name, option|
        object[name] = instance_exec_default(item, option) unless contains_key?(object, name)
        object[name], object[:"#{name}_iv"] = encrypt(object[name]) if option.encrypted?
      end
      object
    end

    #: (Config item, Config::Setting::Option option) -> String?
    def instance_exec_default(item, option)
      item.instance_exec(&option.default) # steep:ignore BlockTypeMismatch
    end

    #: (Config::Serializer | ::Hash[String | Symbol, untyped] object, Symbol key) -> bool
    def contains_key?(object, key)
      (object.try(:marshal_dump) || object).key?(key)
    end
  end
end
