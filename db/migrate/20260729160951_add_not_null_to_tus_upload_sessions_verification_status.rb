class AddNotNullToTusUploadSessionsVerificationStatus < ActiveRecord::Migration[8.1]
  def change
    change_column_null :tus_upload_sessions, :verification_status, false, 'pending'
  end
end
