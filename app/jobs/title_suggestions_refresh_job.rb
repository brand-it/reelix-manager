# frozen_string_literal: true

# Weekly refresh of the FTS5 title index from IMDb's title.basics dataset.
# Scheduled in config/recurring.yml.
class TitleSuggestionsRefreshJob < ApplicationJob
  queue_as :default

  #: () -> void
  def perform
    stats = TitleSuggestions::RefreshService.call
    Rails.logger.info("[TitleSuggestionsRefreshJob] Refreshed #{stats[:kept]} titles")
  end
end
