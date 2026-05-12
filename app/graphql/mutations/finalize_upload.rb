# frozen_string_literal: true

module Mutations
  class FinalizeUpload < Mutations::BaseMutation
    ALLOWED_MEDIA_TYPES = %w[movie tv].freeze #: Array[String]

    description 'Promote a completed tus upload to its final destination. ' \
                'Call this after the tus client has finished uploading all bytes. ' \
                'Fetches metadata from TMDB, builds the correct media path, moves the file, ' \
                'and creates a VideoBlob record.'

    argument :upload_id, String, required: true,
                                 description: 'The tus upload UID returned in the Location header from POST /files'
    argument :tmdb_id, Integer, required: true,
                                description: 'TMDB ID for the movie or TV show'
    argument :filename, String, required: false,
                                description: 'Override the filename (defaults to the filename from tus Upload-Metadata)'
    argument :media_type, String, required: false, default_value: 'movie',
                                  description: "Target media library: 'movie' or 'tv' (defaults to 'movie')"
    argument :season_number, Integer, required: false,
                                      description: "Season number (required when media_type is 'tv')"
    argument :episode_number, Integer, required: false,
                                       description: "Episode number (required when media_type is 'tv')"

    field :video_blob,        Types::VideoBlobType, null: true
    field :destination_path,  String,               null: true
    field :errors,            [String], null: false

    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> bool
    def ready?(upload_id:, tmdb_id:, filename: nil, media_type: 'movie', season_number: nil, episode_number: nil)
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
    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    #: (
    #    upload_id: String,
    #    tmdb_id: Integer,
    #    ?filename: String?,
    #    ?media_type: String,
    #    ?season_number: Integer?,
    #    ?episode_number: Integer?
    #  ) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    def resolve(upload_id:, tmdb_id:, filename: nil, media_type: 'movie', season_number: nil, episode_number: nil)
      # Validate media type - return error instead of raising
      return err("media_type must be one of: #{ALLOWED_MEDIA_TYPES.join(', ')}") unless ALLOWED_MEDIA_TYPES.include?(media_type)

      # Validate TV fields - return error instead of raising
      if media_type == 'tv'
        return err('season_number is required for TV uploads') if season_number.nil?
        return err('episode_number is required for TV uploads') if episode_number.nil?
      end

      # Find tus session
      tus_session = TusUploadSession.find_by(id: upload_id)
      return err('Upload session not found') unless tus_session

      # Check if already finalized
      return err('Upload already finalized') if tus_session.finalized?

      # Queue async promotion job
      PromoteUploadJob.perform_later(
        upload_id:,
        tmdb_id:,
        filename:,
        media_type:,
        season_number:,
        episode_number:
      )

      { video_blob: nil, destination_path: nil, errors: [] }
    end

    private

    #: (String message) -> ::Hash[Symbol, VideoBlob | String | nil | ::Array[String]]
    def err(message)
      { video_blob: nil, destination_path: nil, errors: [message] }
    end
  end
end
