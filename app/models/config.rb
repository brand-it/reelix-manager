# frozen_string_literal: true

class Config < ApplicationRecord
  class << self
    #: () -> Config::Setting
    #: () { (Config::Setting) -> void } -> Config::Setting
    def setting(&block)
      return @setting unless block_given?

      @setting = Setting.call(block)
      @setting.attributes.each_key do |name|
        define_method(:"settings_#{name}") { settings[name] }
        define_method(:"settings_#{name}=") do |val|
          self.settings = { name => val }
        end
      end
    end

    #: () -> Config
    def newest
      order(updated_at: :desc).first || new
    end
  end

  #: () -> Config::Serializer
  def settings
    self.class.setting.load(self, super)
  end

  #: (::Hash[String | Symbol, untyped] hash) -> void
  def settings=(hash)
    super(self.class.setting.dump(self, settings.to_h.with_indifferent_access.merge(hash)))
  end
end
