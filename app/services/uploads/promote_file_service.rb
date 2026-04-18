# frozen_string_literal: true

module Uploads
  # Moves a completed tus upload into its final destination using a staging file
  # within tmp/ so the promotion remains atomic on the local filesystem.
  class PromoteFileService < ApplicationService
    class << self
      #: (upload_id: String, info: ::Hash[String, String?], extension: String, video_blob: VideoBlob) -> void
      def call(upload_id:, info:, extension:, video_blob:)
        new(upload_id:, info:, extension:, video_blob:).call
      end
    end

    # @rbs @upload_id: String
    # @rbs @info: ::Hash[String, String?]
    # @rbs @extension: String
    # @rbs @video_blob: VideoBlob

    #: (upload_id: String, info: ::Hash[String, String?], extension: String, video_blob: VideoBlob) -> void
    def initialize(upload_id:, info:, extension:, video_blob:)
      @upload_id = upload_id
      @info = info
      @extension = extension
      @video_blob = video_blob
    end

    #: () -> void
    def call
      staging_path = move_to_staging
      storage.delete_file(@upload_id, @info) # steep:ignore NoMethod

      destination_dir = @video_blob.directory
      destination_path = @video_blob.media_path
      raise ArgumentError, 'Could not determine destination directory' unless destination_dir
      raise ArgumentError, 'Could not determine destination path' unless destination_path

      FileUtils.mkdir_p(destination_dir)
      FileUtils.mv(staging_path, destination_path)
    end

    private

    #: () -> Object
    def storage
      Tus::Server.opts[:storage]
    end

    #: () -> String
    def move_to_staging
      staging_dir = Rails.root.join('tmp', 'media_staging')
      FileUtils.mkdir_p(staging_dir)

      staging_path = staging_dir.join("#{SecureRandom.uuid}.#{@extension}").to_s
      FileUtils.mv(File.join(storage.directory.to_s, @upload_id), staging_path) # steep:ignore NoMethod
      staging_path
    end
  end
end
