class UploadSession < ApplicationRecord
  STATUSES = %w[pending uploading assembling complete aborted failed].freeze

  before_create :set_id

  validates :filename, presence: true
  validates :total_chunks, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  def chunks_dir
    Rails.root.join("tmp", "uploads", id.to_s)
  end

  def chunk_path(chunk_number)
    chunks_dir.join("chunk_#{chunk_number.to_s.rjust(6, '0')}")
  end

  # Returns the chunk numbers (1-based) that have not yet been received on disk.
  def missing_chunks
    (1..total_chunks).reject { |n| File.exist?(chunk_path(n)) }
  end

  # Authoritative check: all chunk files must be present on disk.
  def upload_complete?
    missing_chunks.empty?
  end

  def assembled_file_path
    return nil if destination_path.blank?
    File.join(destination_path, filename)
  end

  private

  def set_id
    self.id ||= SecureRandom.uuid
  end
end
