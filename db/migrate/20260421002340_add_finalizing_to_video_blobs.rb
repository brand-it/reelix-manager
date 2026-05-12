# frozen_string_literal: true

class AddFinalizingToVideoBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :video_blobs, :finalizing, :boolean, default: false, null: false
    add_index :video_blobs, :finalizing
  end
end