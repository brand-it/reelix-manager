module Mutations
  class FinalizeUpload < Mutations::BaseMutation
    description "Promote a completed tus upload to its final destination. " \
                "Call this after the tus client has finished uploading all bytes."

    argument :upload_id, String, required: true,
      description: "The tus upload UID returned in the Location header from POST /files"
    argument :filename, String, required: false,
      description: "Override the filename (defaults to the filename from tus Upload-Metadata)"
    argument :media_type, String, required: false, default_value: "movie",
      description: "Target media library: 'movie' or 'tv' (defaults to 'movie')"

    field :destination_path, String, null: true
    field :filename, String, null: true
    field :errors, [ String ], null: false

    def ready?(**_args)
      require_upload!
      true
    end

    def resolve(upload_id:, filename: nil, media_type: "movie")
      storage = Tus::Server.opts[:storage]

      begin
        info = storage.read_info(upload_id)
      rescue Tus::NotFound
        return { destination_path: nil, filename: nil, errors: [ "Upload not found: #{upload_id}" ] }
      end

      upload_length = info["Upload-Length"].to_i
      upload_offset = info["Upload-Offset"].to_i

      unless upload_offset >= upload_length && upload_length > 0
        remaining = upload_length - upload_offset
        return { destination_path: nil, filename: nil, errors: [ "Upload incomplete: #{remaining} bytes remaining" ] }
      end

      metadata = decode_tus_metadata(info["Upload-Metadata"])
      resolved_filename = filename || metadata["filename"] || upload_id

      config = Config::Video.newest
      destination_dir = media_type.to_s == "tv" ? config&.settings_tv_path : config&.settings_movie_path

      if destination_dir.blank?
        return { destination_path: nil, filename: nil, errors: [ "No destination path configured. Set the #{media_type} path in Config::Video settings." ] }
      end

      # Sanitize filename to prevent directory traversal
      resolved_filename = File.basename(resolved_filename)

      # Expand paths to resolve symlinks and .. references safely
      destination_dir = File.expand_path(destination_dir)
      dest_path = File.expand_path(File.join(destination_dir, resolved_filename))

      # Defense-in-depth: ensure the resolved destination path stays within the configured directory
      unless dest_path.start_with?(destination_dir + File::SEPARATOR)
        return {
          destination_path: nil,
          filename: nil,
          errors: [ "Resolved path is outside the allowed upload directory." ]
        }
      end

      safe_mkdir_p(destination_dir)
      FileUtils.mv(File.join(storage.directory, upload_id), dest_path)
      storage.delete_file(upload_id, info)

      { destination_path: dest_path, filename: resolved_filename, errors: [] }
    rescue => e
      { destination_path: nil, filename: nil, errors: [ e.message ] }
    end

    private

    def safe_mkdir_p(path)
      expanded_path = File.expand_path(path)
      FileUtils.mkdir_p(expanded_path)
    end

    def decode_tus_metadata(header)
      return {} if header.blank?

      header.split(",").each_with_object({} #: ::Hash[String, String?]
      ) do |pair, hash|
        key, encoded_value = pair.strip.split(" ", 2)
        hash[key] = encoded_value ? Base64.decode64(encoded_value) : nil
      end
    end
  end
end
