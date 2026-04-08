# frozen_string_literal: true

class VideoBlobsController < ApplicationController
  # @rbs @video_blobs: ActiveRecord::Relation
  # @rbs @query: String
  # @rbs @media_type_filter: String

  VALID_MEDIA_TYPES = %w[movie tv].freeze #: Array[String]

  #: () -> void
  def index
    @query = params[:q].to_s.strip #: String
    @media_type_filter = VALID_MEDIA_TYPES.include?(params[:media_type].to_s) ? params[:media_type].to_s : "" #: String

    @video_blobs = VideoBlob
      .by_media_type(@media_type_filter)
      .search_title(@query)
      .order(:title, :season_number, :episode_number) #: ActiveRecord::Relation
  end
end
