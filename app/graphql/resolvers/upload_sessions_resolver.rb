# frozen_string_literal: true

module Resolvers
  class UploadSessionsResolver < Resolvers::BaseResolver
    type [Types::UploadSessionType], null: false

    #: () -> ::Array[TusUploadSession]
    def resolve
      require_upload!
      TusUploadSession
        .where(finalized: false)
        .includes(:doorkeeper_token, :user)
        .order(updated_at: :desc)
        .to_a
    end
  end
end
