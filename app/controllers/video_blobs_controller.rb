# frozen_string_literal: true

class VideoBlobsController < ApplicationController
  # @rbs @video_blobs: Array[VideoBlob]
  # @rbs @query: String
  # @rbs @media_type_filter: String

  VALID_MEDIA_TYPES = %w[movie tv].freeze #: Array[String]

  #: () -> void
  def index
    @query = params[:q].to_s.strip #: String
    requested_media_type = params[:media_type].to_s #: String
    @media_type_filter = VALID_MEDIA_TYPES.include?(requested_media_type) ? requested_media_type : "" #: String
    @video_blobs = load_video_blobs #: Array[VideoBlob]

    respond_to do |format|
      format.html
      format.turbo_stream
    end
  end

  #: () -> void
  def reset_and_resync
    VideoBlob.in_batches.destroy_all
    LibraryScanJob.perform_later

    respond_to do |format|
      format.html { redirect_to video_blobs_path }
    end
  end

  private

  #: () -> Array[VideoBlob]
  def load_video_blobs
    VideoBlob
      .by_media_type(@media_type_filter)
      .search_title(@query)
      .order(:title, :season_number, :episode_number)
      .to_a
  end
end
