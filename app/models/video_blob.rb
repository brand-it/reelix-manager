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
#  extra_type          :integer          default("feature_films"), not null
#  extra_type_number   :integer
#  filename            :string           not null
#  key                 :string           not null
#  media_type          :integer          default("movie"), not null
#  optimized           :boolean          default(FALSE), not null
#  part                :integer
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
  # Sort order is important — matches plex_the_ripper convention.
  EXTRA_TYPES = {
    feature_films:     { dir_name: "Feature Films" },
    behind_the_scenes: { dir_name: "Behind The Scenes" },
    deleted_scenes:    { dir_name: "Deleted Scenes" },
    featurettes:       { dir_name: "Featurettes" },
    interviews:        { dir_name: "Interviews" },
    scenes:            { dir_name: "Scenes" },
    shorts:            { dir_name: "Shorts" },
    trailers:          { dir_name: "Trailers" },
    other:             { dir_name: "Other" }
  }.with_indifferent_access

  enum :media_type, { movie: 0, tv: 1 }
  enum :extra_type, EXTRA_TYPES.keys

  validates :key,        presence: true, uniqueness: true
  validates :filename,   presence: true
  validates :media_type, presence: true
  validates :extra_type, presence: true

  scope :without_tmdb_id,  -> { where(tmdb_id: nil) }
  scope :with_tmdb_id,     -> { where.not(tmdb_id: nil) }
  scope :with_poster,      -> { where.not(poster_url: [ nil, "" ]) }
  scope :movies,           -> { where(media_type: :movie) }
  scope :tv_shows,         -> { where(media_type: :tv) }
  scope :plex_versions,    -> { where(plex_version: true) }
  scope :optimized_blobs,  -> { where(optimized: true) }
  scope :by_media_type,    ->(type) { type.present? ? where(media_type: type) : all }
  scope :search_title,     ->(query) { query.present? ? where("title LIKE ?", "%#{sanitize_sql_like(query)}%") : all }
end
