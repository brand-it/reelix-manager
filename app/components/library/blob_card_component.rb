# frozen_string_literal: true

module Library
  # steep:ignore MethodDefinitionMissing
  class BlobCardComponent < ViewComponent::Base
    #: (blob: VideoBlob) -> void
    def initialize(blob:)
      @blob = blob
    end

    #: VideoBlob
    attr_reader :blob

    #: () -> String
    def title_text
      blob.title.presence || blob.filename
    end

    #: () -> String
    def poster_alt
      "#{title_text} poster"
    end

    #: () -> String?
    def season_episode_label
      return unless blob.tv? && blob.season_number.present?

      label = "S#{format('%02d', blob.season_number)}" #: String
      label += "E#{format('%02d', blob.episode_number)}" if blob.episode_number.present?
      label
    end

    def blob_key
      blob.key
    end
  end
end
