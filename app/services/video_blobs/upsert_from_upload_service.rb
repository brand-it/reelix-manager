# frozen_string_literal: true

module VideoBlobs
  # Creates or updates the VideoBlob record for a finalized upload.
  class UpsertFromUploadService < ApplicationService
    class << self
      #: (video_blob: VideoBlob) -> VideoBlob
      def call(...) = super
    end

    # @rbs @video_blob: VideoBlob

    #: (video_blob: VideoBlob) -> void
    def initialize(video_blob:)
      @video_blob = video_blob
    end

    #: () -> VideoBlob
    def call
      destination_path = video_blob.key.presence || video_blob.media_path
      destination_filename = video_blob.filename.presence || video_blob.generated_filename
      raise ArgumentError, "Could not determine blob destination path" unless destination_path
      raise ArgumentError, "Could not determine blob filename" unless destination_filename

      blob = VideoBlob.find_or_initialize_by(key: destination_path)
      blob.assign_attributes(
        key: destination_path,
        filename: destination_filename,
        title: video_blob.title,
        year: video_blob.year,
        tmdb_id: video_blob.tmdb_id,
        media_type: video_blob.media_type,
        path_extension: video_blob.path_extension,
        episode_title: video_blob.episode_title,
        season_number: video_blob.season_number,
        episode_number: video_blob.episode_number,
        content_type: KeyParserService::VIDEO_MIME_TYPES[video_blob.path_extension.to_s]
      )
      blob.save!
      blob
    end

    private

    attr_reader :video_blob
  end
end
