module Mutations
  class FinalizeUpload < Mutations::BaseMutation
    description "Promote a completed tus upload to its final destination. " \
                "Call this after the tus client has finished uploading all bytes. " \
                "Fetches metadata from TMDB, builds the correct media path, moves the file, " \
                "and creates a VideoBlob record."

    argument :upload_id, String, required: true,
      description: "The tus upload UID returned in the Location header from POST /files"
    argument :tmdb_id, Integer, required: true,
      description: "TMDB ID for the movie or TV show"
    argument :filename, String, required: false,
      description: "Override the filename (defaults to the filename from tus Upload-Metadata)"
    argument :media_type, String, required: false, default_value: "movie",
      description: "Target media library: 'movie' or 'tv' (defaults to 'movie')"
    argument :season_number, Integer, required: false,
      description: "Season number (required when media_type is 'tv')"
    argument :episode_number, Integer, required: false,
      description: "Episode number (required when media_type is 'tv')"

    field :video_blob,        Types::VideoBlobType, null: true
    field :destination_path,  String,               null: true
    field :errors,            [ String ],            null: false

    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> bool
    def ready?(upload_id:, tmdb_id:, filename: nil, media_type: "movie", season_number: nil, episode_number: nil)
      require_upload!
      true
    end

    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    def resolve(upload_id:, tmdb_id:, filename: nil, media_type: "movie", season_number: nil, episode_number: nil)
      validate_tv_fields!(media_type:, season_number:, episode_number:)

      upload = Uploads::TusUploadService.call(upload_id:, filename:)

      config = Config::Video.newest
      return err("No video configuration found. Configure settings first.") unless config.persisted?

      blob = VideoBlob.new(
        tmdb_id:,
        media_type:,
        season_number:,
        episode_number:,
        path_extension: upload[:extension]
      )

      Uploads::TmdbMetadataService.call(video_blob: blob)
      return err("Could not fetch title from TMDB (id: #{tmdb_id})") unless blob.title.present?

      generated_filename = blob.generated_filename
      media_path = blob.media_path
      raise Uploads::TusUploadService::Error, "Could not build media path" unless generated_filename.present? && media_path.present?

      blob.filename = generated_filename
      blob.key = media_path

      Uploads::PromoteFileService.call(
        upload_id:,
        info: upload[:info],
        extension: upload[:extension],
        video_blob: blob
      )

      blob = VideoBlobs::UpsertFromUploadService.call(
        video_blob: blob
      )

      VideoBlobTmdbSyncJob.perform_later(blob.id)

      { video_blob: blob, destination_path: blob.key, errors: [] }
    rescue Uploads::TusUploadService::Error, TheMovieDb::Error, ActiveRecord::RecordInvalid, SystemCallError => e
      err(e.message)
    end

    private

    #: (String message) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    def err(message)
      { video_blob: nil, destination_path: nil, errors: [ message ] }
    end

    #: (media_type: String, season_number: Integer?, episode_number: Integer?) -> void
    def validate_tv_fields!(media_type:, season_number:, episode_number:)
      return unless media_type == "tv"

      raise Uploads::TusUploadService::Error, "season_number is required for TV uploads" if season_number.nil?
      raise Uploads::TusUploadService::Error, "episode_number is required for TV uploads" if episode_number.nil?
    end
  end
end
