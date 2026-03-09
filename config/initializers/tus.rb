require "tus/storage/filesystem"

# Store in-progress uploads in tmp/tus_uploads/. These are the raw upload
# files while the tus protocol is receiving chunks — not the final destination.
Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(
  Rails.root.join("tmp", "tus_uploads")
)

# Maximum upload size (10 GB — adjust to match your use case).
Tus::Server.opts[:max_size] = 10.megabytes
# Incomplete uploads expire after 48 hours of inactivity.
Tus::Server.opts[:expiration_time] = 48.hours
