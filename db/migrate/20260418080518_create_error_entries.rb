class CreateErrorEntries < ActiveRecord::Migration[7.0]
  def change
    create_table :error_entries do |t|
      # Error info
      t.string :error_class, null: false
      t.text :error_message, null: false
      t.text :backtrace, null: false

      # Grouping
      t.string :fingerprint, null: false

      # Status tracking
      t.integer :status, default: 0, null: false

      # Request context (nil if from job)
      t.string :request_url
      t.string :request_method
      t.string :request_path
      t.text :request_params

      # Job context (nil if from request)
      t.string :job_class
      t.string :job_id
      t.string :job_queue
      t.text :job_arguments

      # User context
      t.integer :user_id
      t.string :user_email

      # Metadata
      t.string :environment

      t.timestamps
    end

    add_index :error_entries, :fingerprint
    add_index :error_entries, :error_class
    add_index :error_entries, :status
    add_index :error_entries, :created_at
  end
end
