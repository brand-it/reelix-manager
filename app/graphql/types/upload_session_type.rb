module Types
  class UploadSessionType < Types::BaseObject
    field :id, ID, null: false
    field :filename, String, null: false
    field :file_size, Integer, null: true
    field :mime_type, String, null: true
    field :status, String, null: false
    field :total_chunks, Integer, null: false
    field :received_chunks, Integer, null: false
    field :missing_chunks, [ Integer ], null: false, description: "Chunk numbers (1-based) not yet received — use this to resume an interrupted upload"
    field :upload_complete, Boolean, null: false
    field :error_message, String, null: true, description: "Set when status is 'failed'"

    def missing_chunks
      object.missing_chunks
    end

    def upload_complete
      object.upload_complete?
    end
  end
end
