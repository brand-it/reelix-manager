class Config < ApplicationRecord
  class << self
    #: () -> Config::Setting
    #: () { (Config::Setting) -> void } -> Config::Setting
    def setting(&block)
      return @setting unless block_given? # steep:ignore UnknownInstanceVariable

      @setting = Setting.call(block) # steep:ignore UnknownInstanceVariable, ArgumentTypeMismatch
      @setting.attributes.each_key do |name| # steep:ignore UnknownInstanceVariable
        define_method(:"settings_#{name}") { settings[name] } # steep:ignore NoMethod
        define_method(:"settings_#{name}=") { |val| self.settings = { name => val } } # steep:ignore NoMethod, UnannotatedEmptyCollection
      end
    end

    #: () -> instance
    def newest
      order(updated_at: :desc).first || new # steep:ignore NoMethod
    end
  end

  #: () -> Config::Serializer
  def settings
    self.class.setting.load(self, super) # steep:ignore UnexpectedSuper
  end

  #: (::Hash[untyped, untyped] hash) -> void
  def settings=(hash)
    super(self.class.setting.dump(self, settings.to_h.with_indifferent_access.merge(hash))) # steep:ignore UnexpectedSuper
  end
end
