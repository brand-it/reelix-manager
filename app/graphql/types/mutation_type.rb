# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :finalize_upload, mutation: Mutations::FinalizeUpload
    field :abort_upload, mutation: Mutations::AbortUpload
  end
end
