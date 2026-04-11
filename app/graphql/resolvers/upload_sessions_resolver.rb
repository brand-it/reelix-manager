# frozen_string_literal: true

module Resolvers
  class UploadSessionsResolver < Resolvers::BaseResolver
    type [ Types::UploadSessionType ], null: false

    #: () -> ::Array[Uploads::SessionSnapshot]
    def resolve
      require_upload!
      Uploads::ActiveUploadsService.call
    end
  end
end
