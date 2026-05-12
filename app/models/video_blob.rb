# frozen_string_literal: true

# == Schema Information
#
# Table name: video_blobs
#
#  id                  :integer          not null, primary key
#  content_type        :string
#  edition             :string
#  episode_last_number :integer
#  episode_number      :integer
#  episode_title       :string
#  extra_type          :integer          default("feature_films"), not null
#  extra_type_number   :integer
#  filename            :string           not null
#  key                 :string           not null
#  media_type          :integer          default("movie"), not null
#  optimized           :boolean          default(FALSE), not null
#  part                :integer
#  path_extension      :string
#  plex_version        :boolean          default(FALSE), not null
#  poster_url          :string
#  season_number       :integer
#  title               :string
#  tmdb_id             :integer
#  year                :integer
#  created_at          :datetime         not null
#  updated_at          :datetime         not null
#
# Indexes
#
#  index_video_blobs_on_key                        (key) UNIQUE
#  index_video_blobs_on_media_type_and_tmdb_id     (media_type,tmdb_id)
#  index_video_blobs_on_tmdb_id                    (tmdb_id)
#
class VideoBlob < ApplicationRecord
  # @rbs @video_config: Config::Video?

  # Sort order is important — matches plex_the_ripper convention.
  EXTRA_TYPES = {
    feature_films: { dir_name: 'Feature Films' },
    behind_the_scenes: { dir_name: 'Behind The Scenes' },
    deleted_scenes: { dir_name: 'Deleted Scenes' },
    featurettes: { dir_name: 'Featurettes' },
    interviews: { dir_name: 'Interviews' },
    scenes: { dir_name: 'Scenes' },
    shorts: { dir_name: 'Shorts' },
    trailers: { dir_name: 'Trailers' },
    other: { dir_name: 'Other' }
  }.with_indifferent_access

  enum :media_type, { movie: 0, tv: 1 }
  enum :extra_type, EXTRA_TYPES.keys

  validates :key,        presence: true, uniqueness: true
  validates :filename,   presence: true
  validates :media_type, presence: true
  validates :extra_type, presence: true
  # Skip key validation when finalizing (file not yet moved)
  validates :key, presence: false, if: -> { finalizing }
  scope :without_tmdb_id,  -> { where(tmdb_id: nil) }
  scope :with_tmdb_id,     -> { where.not(tmdb_id: nil) }
  scope :with_poster,      -> { where.not(poster_url: [nil, '']) }
  scope :movies,           -> { where(media_type: :movie) }
  scope :tv_shows,         -> { where(media_type: :tv) }
  scope :plex_versions,    -> { where(plex_version: true) }
  scope :optimized_blobs,  -> { where(optimized: true) }
  scope :by_media_type,    ->(type) { type.present? ? where(media_type: type) : all }
  scope :search_title,     ->(query) { query.present? ? where('title LIKE ?', "%#{sanitize_sql_like(query)}%") : all }

  # Returns the canonical display name for this media item (no extension, no directory).
  #
  # Movie:  "Batman Begins (2005)"
  # TV:     "Breaking Bad (2008) - s01e01"
  # Returns nil when required fields (title) are missing,
  # or when season/episode are missing for a TV blob.
  #: () -> String?
  def media_name
    show_name = show_name_for_path
    return unless show_name

    return show_name if movie?

    episode_code = episode_code_for_path
    return unless episode_code

    "#{show_name} - #{episode_code}"
  end

  # Returns the filename derived from this blob's media attributes plus the
  # virtual path fields used during upload-time path construction.
  # Movie: "Batman Begins (2005).mkv"
  # TV:    "Breaking Bad (2008) - s01e01 - Pilot.mkv"
  #: () -> String?
  def generated_filename
    show_name = show_name_for_path
    return unless show_name && path_extension.present?

    sanitized_extension = path_extension.to_s.downcase.delete_prefix('.')
    return "#{show_name}.#{sanitized_extension}" unless tv?

    episode_code = episode_code_for_path
    return unless episode_code

    episode_title_value = episode_title
    sanitized_episode_title = episode_title_value.present? ? sanitize_path_component(episode_title_value) : nil
    file_base =
      if sanitized_episode_title.present?
        "#{show_name} - #{episode_code} - #{sanitized_episode_title}"
      else
        "#{show_name} - #{episode_code}"
      end

    "#{file_base}.#{sanitized_extension}"
  end

  # Returns the absolute media path for this blob.
  #
  # Movie: "/media/movies/Batman Begins (2005)/Batman Begins (2005).mkv"
  # TV:    "/media/tv/Breaking Bad (2008)/Season 01/Breaking Bad (2008) - s01e01 - Pilot.mkv"
  #
  # Returns nil when the media root, media name, or filename is unavailable.
  #: () -> String?
  def media_path
    root = media_root_for_path
    relative_path = relative_media_path
    return unless root.present? && relative_path.present?

    File.join(root, relative_path)
  end

  #: () -> String?
  def directory
    root = media_root_for_path
    relative_path = relative_media_path
    return unless root.present? && relative_path.present?

    File.join(root, File.dirname(relative_path))
  end

  private

  #: () -> String?
  def relative_media_path
    show_name = show_name_for_path
    filename_for_path = filename.presence || generated_filename
    return unless show_name.present? && filename_for_path.present?

    return "#{show_name}/#{filename_for_path}" if movie?
    return unless season_number.present?

    padded_season = season_number.to_s.rjust(2, '0')
    "#{show_name}/Season #{padded_season}/#{filename_for_path}"
  end

  #: () -> String?
  def show_name_for_path
    title_value = title
    return unless title_value.present?

    sanitized_title = sanitize_path_component(title_value)
    year_part = year ? " (#{year})" : ''
    "#{sanitized_title}#{year_part}"
  end

  #: () -> String?
  def episode_code_for_path
    return unless season_number.present? && episode_number.present?

    padded_season  = season_number.to_s.rjust(2, '0')
    padded_episode = episode_number.to_s.rjust(2, '0')
    "s#{padded_season}e#{padded_episode}"
  end

  #: (String name) -> String
  def sanitize_path_component(name)
    name
      .gsub(%r{[/\\]}, '-')
      .gsub(/\.\.+/, '.')
      .gsub("\x00", '')
      .strip
  end

  #: () -> String?
  def media_root_for_path
    return tv_path if tv?

    movie_path
  end

  #: () -> String?
  def movie_path
    video_config&.settings_movie_path
  end

  #: () -> String?
  def tv_path
    video_config&.settings_tv_path
  end

  #: () -> Config::Video?
  def video_config
    @video_config ||= Config::Video.newest
  end
end
