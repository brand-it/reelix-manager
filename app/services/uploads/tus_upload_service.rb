# frozen_string_literal: true

module Uploads
  # Loads and validates a completed tus upload, and resolves the source filename
  # and normalized extension for later path construction.
  class TusUploadService < ApplicationService
    class Error < StandardError; end

    class << self
      #: (upload_id: String, ?filename: String?) -> { info: ::Hash[String, String?], source_filename: String, extension: String }
      def call(upload_id:, filename: nil)
        new(upload_id:, filename:).call
      end
    end

    # @rbs @upload_id: String
    # @rbs @filename: String?

    #: (upload_id: String, ?filename: String?) -> void
    def initialize(upload_id:, filename: nil)
      @upload_id = upload_id
      @filename = filename
    end

    #: () -> { info: ::Hash[String, String?], source_filename: String, extension: String }
    def call
      info = read_upload_info
      ensure_upload_complete!(info)

      source_filename = resolved_filename(info['Upload-Metadata'])

      {
        info: info,
        source_filename: source_filename,
        extension: resolved_extension(source_filename)
      }
    end

    private

    #: () -> Object
    def storage
      Tus::Server.opts[:storage]
    end

    #: () -> ::Hash[String, String?]
    def read_upload_info
      storage.read_info(@upload_id) # steep:ignore NoMethod
    rescue Tus::NotFound
      raise Error, "Upload not found: #{@upload_id}"
    end

    #: (::Hash[String, String?]) -> void
    def ensure_upload_complete!(info)
      upload_length = info['Upload-Length'].to_i
      upload_offset = info['Upload-Offset'].to_i

      return if upload_offset >= upload_length && upload_length.positive?

      remaining = upload_length - upload_offset
      raise Error, "Upload incomplete: #{remaining} bytes remaining"
    end

    #: (String? header) -> String
    def resolved_filename(header)
      metadata = decode_tus_metadata(header)
      @filename || metadata['filename'] || 'upload'
    end

    #: (String source_filename) -> String
    def resolved_extension(source_filename)
      File.extname(source_filename.to_s).delete_prefix('.').downcase.presence || 'mkv'
    end

    #: (String? header) -> ::Hash[String, String?]
    def decode_tus_metadata(header)
      return {} if header.blank?

      acc = {} #: ::Hash[String, String?]
      header.split(',').each_with_object(acc) do |pair, hash|
        key, encoded_value = pair.strip.split(' ', 2) # steep:ignore NoMethod
        next unless key

        hash[key] = encoded_value ? Base64.decode64(encoded_value) : nil
      end
    end
  end
end
