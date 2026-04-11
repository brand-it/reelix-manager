class AddPathMetadataToVideoBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :video_blobs, :path_extension, :string
    add_column :video_blobs, :episode_title, :string
  end
end
