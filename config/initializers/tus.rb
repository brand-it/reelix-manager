require "tus/storage/filesystem"

# Store in-progress uploads in tmp/tus_uploads/. These are the raw upload
# files while the tus protocol is receiving chunks — not the final destination.
Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(
  Rails.root.join("tmp", "tus_uploads")
)

# Maximum upload size (100 GB — adjust to match your use case).
Tus::Server.opts[:max_size] = 100.gigabytes
# Incomplete uploads expire after 48 hours of inactivity.
Tus::Server.opts[:expiration_time] = 48.hours

# Authenticate tus uploads using Doorkeeper OAuth tokens
# The Bearer token from Authorization header is validated before allowing uploads
Tus::Server.before_create do |uid, info|
  auth_header = self.request.headers["Authorization"]

  # Skip auth check if no Authorization header (for local dev)
  # Remove this in production
  next if auth_header.blank?

  # Extract token from "Bearer <token>"
  token_string = auth_header.gsub(/^Bearer\s+/i, "")

  # Use Doorkeeper's token introspection
  token = Doorkeeper::OAuth::Token.find_by_token(token_string)

  if token.blank? || token.expired?
    self.response.status = 401
    self.response.write("Unauthorized: Invalid or expired token")
    self.request.halt
  end

  # Check that token has upload scope
  unless token.includes_scope?("upload")
    self.response.status = 403
    self.response.write("Forbidden: upload scope required")
    self.request.halt
  end
end

# Log when uploads complete for debugging
Tus::Server.after_finish do |uid, info|
  Rails.logger.info("Tus upload completed: #{uid} #{info.length} bytes")
end
