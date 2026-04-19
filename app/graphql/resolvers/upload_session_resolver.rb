# frozen_string_literal: true

module Resolvers
  class UploadSessionResolver < Resolvers::BaseResolver
    type Types::UploadSessionType, null: true

    argument :id, ID, required: true, description: 'Upload session ID'

    #: (id: String) -> Uploads::SessionSnapshot?
    def resolve(id:)
      require_upload!
      all_uploads = Uploads::ActiveUploadsService.call
      all_uploads.find { |session| session.id == id }
    end
  end
end
