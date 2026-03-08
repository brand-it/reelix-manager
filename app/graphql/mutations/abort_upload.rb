module Mutations
  class AbortUpload < Mutations::BaseMutation
    description "Abort a tus upload and delete all uploaded data. " \
                "Equivalent to DELETE /files/:uid but callable from GraphQL."

    argument :upload_id, String, required: true,
      description: "The tus upload UID to abort"

    field :success, Boolean, null: false
    field :errors, [ String ], null: false

    def resolve(upload_id:)
      storage = Tus::Server.opts[:storage]

      begin
        info = storage.read_info(upload_id)
      rescue Tus::NotFound
        return { success: false, errors: [ "Upload not found: #{upload_id}" ] }
      end

      storage.delete_file(upload_id, info)

      { success: true, errors: [] }
    rescue => e
      { success: false, errors: [ e.message ] }
    end
  end
end
