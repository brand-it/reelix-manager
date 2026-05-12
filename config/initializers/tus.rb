# frozen_string_literal: true

require 'tus/storage/filesystem'

# Store in-progress uploads in tmp/tus_uploads/. These are the raw upload
# files while the tus protocol is receiving chunks — not the final destination.
Tus::Server.opts[:storage] = Tus::Storage::Filesystem.new(
  Rails.root.join('tmp', 'tus_uploads')
)

# Maximum upload size (100 GB — adjust to match your use case).
Tus::Server.opts[:max_size] = 100.gigabytes
# Incomplete uploads expire after 48 hours of inactivity.
Tus::Server.opts[:expiration_time] = 48.hours

# Authenticate tus uploads using Doorkeeper OAuth tokens AND track upload sessions.
# NOTE: tus-server 2.3.0 only stores ONE block per hook type (opts[:hooks][hook] = block).
#       Registering multiple before_create blocks causes the later ones to overwrite the earlier.
#       We merge auth validation + session tracking into a single block to ensure both run.
Tus::Server.before_create do |uid, info|
  # --- Auth validation ---
  auth_header = request.headers['Authorization']

  # Skip auth check if no Authorization header (for local dev)
  # Remove this in production
  next if auth_header.blank?

  # Use Doorkeeper's token introspection via the access token model
  token_string = auth_header.gsub(/^Bearer\s+/i, '')
  token = Doorkeeper::AccessToken.by_token(token_string)

  if token.blank? || !token.accessible?
    response.status = 401
    response.write('Unauthorized: Invalid or expired token')
    request.halt
  end

  # Check that token has upload scope
  unless token.includes_scope?('upload')
    response.status = 403
    response.write('Forbidden: upload scope required')
    request.halt
  end

  # --- Session tracking ---
  user_id = token&.resource_owner_id
  token_id = token&.id

  # Extract metadata
  metadata = info['Upload-Metadata'] || ''

  # Create session record
  TusUploadSession.create!(
    id: uid,
    filename: TusMetadataHelper.extract_filename(metadata) || uid,
    upload_length: info.length.to_i,
    mime_type: TusMetadataHelper.extract_mime_type(metadata),
    metadata: metadata,
    user_id: user_id,
    doorkeeper_token_id: token_id
  )
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.warn "[TusHook] Failed to create session: #{e.message}"
end

# After create: ensure record exists (idempotent)
Tus::Server.after_create do |uid, info|
  unless TusUploadSession.exists?(uid)
    token_string = request.headers['Authorization']&.gsub(/^Bearer\s+/i, '')
    token = token_string ? Doorkeeper::AccessToken.by_token(token_string) : nil

    TusUploadSession.create!(
      id: uid,
      filename: TusMetadataHelper.extract_filename(info['Upload-Metadata']) || uid,
      upload_length: info.length.to_i,
      metadata: info['Upload-Metadata'] || '',
      user_id: token&.resource_owner_id,
      doorkeeper_token_id: token&.id
    )
  end
rescue ActiveRecord::RecordInvalid => e
  Rails.logger.warn "[TusHook] Failed to create session (after_create): #{e.message}"
end

# After finish: log completion (do NOT set finalized=true here)
# finalized is set by FinalizeUpload mutation after promotion
Tus::Server.after_finish do |uid, info|
  Rails.logger.info("Tus upload completed: #{uid} #{info.length} bytes")
end

# After terminate: cleanup session record
Tus::Server.after_terminate do |uid, _info|
  TusUploadSession.find_by(id: uid)&.destroy
rescue ActiveRecord::RecordNotFound => e
  Rails.logger.debug "[TusHook] Session already deleted: #{e.message}"
end

# Helper module for tus metadata extraction
module TusMetadataHelper
  def self.extract_filename(metadata)
    return nil unless metadata.present?

    parts = metadata.split(',').map(&:strip)
    filename_part = parts.find { |p| p.start_with?('filename') }
    return nil unless filename_part

    # Decode base64-encoded filename
    encoded = filename_part.split.last
    Base64.strict_decode64(encoded) if encoded.present?
  rescue ArgumentError, Base64::DecodeError
    nil
  end

  def self.extract_mime_type(metadata)
    return nil unless metadata.present?

    parts = metadata.split(',').map(&:strip)
    mime_part = parts.find { |p| p.start_with?('mime_type') }
    return nil unless mime_part

    mime_part.split.last
  end
end
