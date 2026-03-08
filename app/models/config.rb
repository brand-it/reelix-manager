class Config < ApplicationRecord
  class << self
    def setting(&block)
      return @setting unless block_given?

      @setting = Setting.call(block)
      @setting.attributes.each_key do |name|
        define_method(:"settings_#{name}") { settings[name] }
        define_method(:"settings_#{name}=") { |val| self.settings = { name => val } }
      end
    end

    def newest
      order(updated_at: :desc).first || new
    end
  end

  def settings
    self.class.setting.load(self, super)
  end

  def settings=(hash)
    super(self.class.setting.dump(self, settings.to_h.with_indifferent_access.merge(hash)))
  end
end
