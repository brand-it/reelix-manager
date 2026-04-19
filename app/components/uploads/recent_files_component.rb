# frozen_string_literal: true

module Uploads
  class RecentFilesComponent < ViewComponent::Base
    #: (recent_video_blobs: ActiveRecord::Relation) -> void
    def initialize(recent_video_blobs:)
      @recent_video_blobs = recent_video_blobs
    end

    #: ActiveRecord::Relation
    attr_reader :recent_video_blobs
  end
end
