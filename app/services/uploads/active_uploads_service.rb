# frozen_string_literal: true

module Uploads
  SessionSnapshot = Data.define(
    :id,
    :filename,
    :upload_length,
    :upload_offset,
    :status,
    :created_at,
    :updated_at,
    :expires_at
  )

  class SessionSnapshot
    #: () -> Integer
    def bytes_remaining
      [ upload_length - upload_offset, 0 ].max
    end

    #: () -> Integer
    def progress_percent
      return 0 unless upload_length.positive?

      ((upload_offset.to_f / upload_length) * 100).floor
    end

    #: () -> bool
    def upload_complete
      upload_length.positive? && upload_offset >= upload_length
    end
  end

  # Reads the live tus upload state from the filesystem storage directory so the
  # app can display incomplete uploads and their current byte offsets.
  class ActiveUploadsService < ApplicationService
    class << self
      #: () -> ::Array[SessionSnapshot]
      def call(...) = super
    end

    #: () -> ::Array[SessionSnapshot]
    def call
      info_paths
        .map { |info_path| build_snapshot(info_path) }
        .sort_by(&:updated_at)
        .reverse
    end

    private

    #: () -> Pathname
    def storage_directory
      Tus::Server.opts[:storage].directory # steep:ignore NoMethod
    end

    #: () -> ::Array[Pathname]
    def info_paths
      Dir.glob(storage_directory.join("*.info").to_s).map { |path| Pathname(path) }
    end

    #: (Pathname info_path) -> SessionSnapshot
    def build_snapshot(info_path)
      uid = info_path.basename(".info").to_s
      info = JSON.parse(info_path.binread)
      data_path = storage_directory.join(uid)
      updated_at = [ info_path.mtime, data_path.exist? ? data_path.mtime : info_path.mtime ].max

      upload_length = info["Upload-Length"].to_i
      upload_offset = info["Upload-Offset"].to_i

      SessionSnapshot.new(
        id: uid,
        filename: resolved_filename(info["Upload-Metadata"], uid),
        upload_length: upload_length,
        upload_offset: upload_offset,
        status: upload_status(upload_length, upload_offset),
        created_at: data_path.exist? ? data_path.ctime : info_path.ctime,
        updated_at: updated_at,
        expires_at: updated_at + tus_expiration_time
      )
    end

    #: (String? header, String uid) -> String
    def resolved_filename(header, uid)
      metadata = decode_tus_metadata(header)
      metadata["filename"] || uid
    end

    #: (String? header) -> ::Hash[String, String?]
    def decode_tus_metadata(header)
      return {} if header.blank?

      acc = {} #: ::Hash[String, String?]
      header.split(",").each_with_object(acc) do |pair, hash|
        key, encoded_value = pair.strip.split(" ", 2) # steep:ignore NoMethod
        next unless key

        hash[key] = encoded_value ? Base64.decode64(encoded_value) : nil
      end
    end

    #: (Integer upload_length, Integer upload_offset) -> String
    def upload_status(upload_length, upload_offset)
      return "pending" if upload_offset.zero?
      return "ready_to_finalize" if upload_length.positive? && upload_offset >= upload_length

      "uploading"
    end

    #: () -> Integer
    def tus_expiration_time
      Tus::Server.opts[:expiration_time].to_i # steep:ignore NoMethod
    end
  end
end
