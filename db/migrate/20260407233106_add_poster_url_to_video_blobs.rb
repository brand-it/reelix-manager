class AddPosterUrlToVideoBlobs < ActiveRecord::Migration[8.1]
  def change
    add_column :video_blobs, :poster_url, :string
  end
end
