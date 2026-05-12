# frozen_string_literal: true

module Resolvers
  class UploadSessionResolver < Resolvers::BaseResolver
    type Types::UploadSessionType, null: true

    argument :id, ID, required: true, description: 'Upload session ID'

    #: (id: String) -> TusUploadSession?
    def resolve(id:)
      require_upload!
      TusUploadSession.find_by(id: id)
    end
  end
end
