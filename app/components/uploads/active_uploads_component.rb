# frozen_string_literal: true

module Uploads
  class ActiveUploadsComponent < ViewComponent::Base
    #: (active_uploads: Array[SessionSnapshot]) -> void
    def initialize(active_uploads:)
      @active_uploads = active_uploads
    end

    #: Array[SessionSnapshot]
    attr_reader :active_uploads
  end
end
