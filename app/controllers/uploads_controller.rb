# frozen_string_literal: true

class UploadsController < ApplicationController
  # @rbs @active_uploads: Array[Uploads::SessionSnapshot]
  # @rbs @recent_video_blobs: ActiveRecord::Relation

  #: () -> void
  def index
    @active_uploads = Uploads::ActiveUploadsService.call #: Array[Uploads::SessionSnapshot]
    @recent_video_blobs = VideoBlob.where({}).order(created_at: :desc).limit(12) #: ActiveRecord::Relation
  end
end
