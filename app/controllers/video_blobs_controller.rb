# frozen_string_literal: true

class VideoBlobsController < ApplicationController
  # @rbs @video_blobs: ActiveRecord::Relation
  # @rbs @query: String
  # @rbs @media_type_filter: String

  #: Array[String]
  VALID_MEDIA_TYPES = %w[movie tv].freeze

  #: () -> void
  def index
    @query = params[:q].to_s.strip #: String
    @media_type_filter = VALID_MEDIA_TYPES.include?(params[:media_type].to_s) ? params[:media_type].to_s : "" #: String

    scope = VideoBlob.all
    scope = scope.where(media_type: @media_type_filter) if @media_type_filter.present?
    scope = scope.where("title LIKE ?", "%#{@query}%") if @query.present?

    @video_blobs = scope.order(:title, :season_number, :episode_number) #: ActiveRecord::Relation
  end
end
