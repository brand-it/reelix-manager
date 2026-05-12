# frozen_string_literal: true

class AddFingerprintToTusUploadSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :tus_upload_sessions, :fingerprint, :string
    add_index :tus_upload_sessions, :fingerprint
  end
end
