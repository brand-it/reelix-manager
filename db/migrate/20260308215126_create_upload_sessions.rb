class CreateUploadSessions < ActiveRecord::Migration[8.1]
  def change
    create_table :upload_sessions, id: false do |t|
      t.string :id, primary_key: true, null: false
      t.string :filename, null: false
      t.bigint :file_size
      t.string :mime_type
      t.string :status, null: false, default: "pending"
      t.integer :total_chunks, null: false
      t.integer :received_chunks, null: false, default: 0
      t.string :destination_path

      t.timestamps
    end
  end
end
