# frozen_string_literal: true

class CreateTusUploadSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :tus_upload_sessions, id: :string do |t|
      t.string :filename, null: false
      t.bigint :upload_length, null: false, limit: 8  # Support files up to 100GB+
      t.string :mime_type
      t.text :metadata  # JSON blob for Upload-Metadata header
      t.boolean :finalized, default: false, null: false
      t.integer :video_blob_id  # FK to video_blobs when finalized
      t.integer :user_id  # FK to users (resource owner of token)
      t.integer :doorkeeper_token_id  # FK to oauth_access_tokens for device tracking
      t.timestamps
    end

    add_index :tus_upload_sessions, :finalized
    add_index :tus_upload_sessions, :video_blob_id
    add_index :tus_upload_sessions, :user_id
    add_index :tus_upload_sessions, :doorkeeper_token_id
    add_index :tus_upload_sessions, %i[finalized updated_at]
  end
end