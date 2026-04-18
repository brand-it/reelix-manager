# frozen_string_literal: true

class CreateVideoBlobs < ActiveRecord::Migration[8.1]
  def change
    create_table :video_blobs do |t|
      t.string  :key,                 null: false
      t.string  :filename,            null: false
      t.string  :content_type
      t.integer :media_type, null: false, default: 0
      t.integer :tmdb_id
      t.string  :title
      t.integer :year
      t.string  :edition
      t.integer :season_number
      t.integer :episode_number
      t.integer :episode_last_number
      t.integer :part
      t.integer :extra_type, null: false, default: 0
      t.integer :extra_type_number
      t.boolean :plex_version,        null: false, default: false
      t.boolean :optimized,           null: false, default: false

      t.timestamps
    end

    add_index :video_blobs, :key, unique: true
    add_index :video_blobs, :tmdb_id
    add_index :video_blobs, %i[media_type tmdb_id], name: 'index_video_blobs_on_media_type_and_tmdb_id'
  end
end
