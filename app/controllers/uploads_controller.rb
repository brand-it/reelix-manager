# frozen_string_literal: true

class UploadsController < ApplicationController
  # @rbs @active_uploads: Array[TusUploadSession]
  # @rbs @recent_video_blobs: ActiveRecord::Relation

  #: () -> void
  def index
    @active_uploads = TusUploadSession
                      .where(finalized: false)
                      .includes(:doorkeeper_token, :user)
                      .order(updated_at: :desc)
                      .to_a
    @recent_video_blobs = VideoBlob.where({}).order(created_at: :desc).limit(12) #: ActiveRecord::Relation

    respond_to do |format|
      format.turbo_stream
      format.html
    end
  end
end
