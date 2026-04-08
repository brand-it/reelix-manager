# frozen_string_literal: true

# Base class for all service objects.
#
# Subclasses must implement #call. Constructor arguments set up state; #call
# executes the behaviour.
#
# Usage:
#   MyService.call(arg)           # class-level shortcut
#   MyService.new(arg).call       # equivalent long form
class ApplicationService
  class << self
    def call(...)
      new(...).call
    end
  end

  #: () -> void
  def call
    raise NotImplementedError, "#{self.class}#call is not implemented"
  end
end
