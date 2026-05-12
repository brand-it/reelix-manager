# frozen_string_literal: true

module Uploads
  class ActiveUploadsComponent < ViewComponent::Base
    #: (active_uploads: Array[TusUploadSession]) -> void
    def initialize(active_uploads:)
      @active_uploads = active_uploads
    end

    #: Array[TusUploadSession]
    attr_reader :active_uploads
  end
end
