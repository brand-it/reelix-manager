# frozen_string_literal: true

module Types
  class MutationType < Types::BaseObject
    field :finalize_upload, mutation: Mutations::FinalizeUpload
  end
end
