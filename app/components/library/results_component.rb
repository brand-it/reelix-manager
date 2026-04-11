# frozen_string_literal: true

module Library
  class ResultsComponent < ViewComponent::Base
    #: (video_blobs: Array[VideoBlob], query: String) -> void
    def initialize(video_blobs:, query:)
      @video_blobs = video_blobs
      @query = query
    end

    #: Array[VideoBlob]
    attr_reader :video_blobs

    #: String
    attr_reader :query

    #: () -> bool
    def empty?
      video_blobs.empty?
    end
  end
end
