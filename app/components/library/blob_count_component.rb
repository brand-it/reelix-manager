# frozen_string_literal: true

module Library
  class BlobCountComponent < ViewComponent::Base
    #: (count: Integer) -> void
    def initialize(count:)
      @count = count
    end

    #: Integer
    attr_reader :count

    #: () -> String
    def label
      "#{count} video#{'s' unless count == 1}"
    end
  end
end
