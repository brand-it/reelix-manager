# frozen_string_literal: true

require "find"

# Walks the movie and TV library directories defined in Config::Video and
# upserts a VideoBlob record for every video file found. Files that no longer
# exist on disk have their VideoBlob records removed.
#
# Usage:
#   result = LibraryScannerService.call
#   result[:added]   # => 12
#   result[:updated] # => 3
#   result[:removed] # => 1
#   result[:skipped] # => 0
class LibraryScannerService < ApplicationService
  class << self
    #: () -> ::Hash[Symbol, Integer]
    def call(...) = super
  end

  #: () -> ::Hash[Symbol, Integer]
  def call
    config = Config::Video.newest
    unless config
      Rails.logger.warn("[LibraryScannerService] No Config::Video record found — aborting scan.")
      return empty_stats
    end

    stats = empty_stats
    scanned_keys = [] #: Array[String]

    [ { path: config.settings_movie_path, type: :movie },
      { path: config.settings_tv_path,    type: :tv } ].each do |dir|
      next if dir[:path].blank? || !Dir.exist?(dir[:path].to_s)

      scan_directory(dir[:path].to_s, stats, scanned_keys)
    end

    remove_stale(scanned_keys, stats)

    Rails.logger.info("[LibraryScannerService] Scan complete — #{stats.inspect}")
    stats
  end

  private

  #: (String directory, ::Hash[Symbol, Integer] stats, ::Array[String] scanned_keys) -> void
  def scan_directory(directory, stats, scanned_keys)
    Find.find(directory) do |path| # steep:ignore NoMethod
      next unless File.file?(path)

      blob_data = KeyParserService.call(path)
      next stats[:skipped] += 1 if blob_data.nil?

      scanned_keys << path
      upsert_blob(path, blob_data, stats)
    end
  end

  #: (String path, KeyParserService::BlobData blob_data, ::Hash[Symbol, Integer] stats) -> void
  def upsert_blob(path, blob_data, stats)
    attrs = build_attrs(blob_data)
    blob  = VideoBlob.find_by(key: path)

    if blob
      blob.update!(attrs)
      stats[:updated] += 1
    else
      VideoBlob.create!(attrs.merge(key: path))
      stats[:added] += 1
    end
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error("[LibraryScannerService] Failed to upsert #{path}: #{e.message}")
    stats[:skipped] += 1
  end

  #: (KeyParserService::BlobData blob_data) -> ::Hash[Symbol, untyped]
  def build_attrs(blob_data)
    {
      filename:            blob_data.filename,
      content_type:        blob_data.content_type,
      media_type:          blob_data.movie? ? :movie : :tv,
      title:               blob_data.title,
      year:                blob_data.year,
      edition:             blob_data.edition,
      season_number:       blob_data.season,
      episode_number:      blob_data.episode,
      episode_title:       blob_data.episode_title,
      episode_last_number: blob_data.episode_last,
      part:                blob_data.part,
      path_extension:      blob_data.filename.split(".").last&.downcase,
      extra_type:          blob_data.extra_type,
      extra_type_number:   blob_data.extra_number,
      plex_version:        blob_data.plex_version,
      optimized:           blob_data.optimized
    }
  end

  #: (::Array[String] scanned_keys, ::Hash[Symbol, Integer] stats) -> void
  def remove_stale(scanned_keys, stats)
    scanned_set = Set.new(scanned_keys)
    VideoBlob.find_each do |blob|
      next if scanned_set.include?(blob.key)

      blob.destroy!
      stats[:removed] += 1
    rescue ActiveRecord::RecordNotDestroyed => e
      Rails.logger.error("[LibraryScannerService] Failed to remove #{blob.key}: #{e.message}")
    end
  end

  #: () -> ::Hash[Symbol, Integer]
  def empty_stats
    { added: 0, updated: 0, removed: 0, skipped: 0 }
  end
end
