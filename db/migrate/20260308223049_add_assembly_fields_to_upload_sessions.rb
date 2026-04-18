# frozen_string_literal: true

class AddAssemblyFieldsToUploadSessions < ActiveRecord::Migration[8.1]
  def change
    add_column :upload_sessions, :error_message, :text
  end
end
