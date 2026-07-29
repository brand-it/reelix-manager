class AddDigestFieldsToTusUploadSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :tus_upload_sessions, :client_digest, :string
    add_column :tus_upload_sessions, :server_digest, :string
    add_column :tus_upload_sessions, :verification_status, :string, default: 'pending', null: false
  end
end
