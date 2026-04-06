class UploadSession < ApplicationRecord
  STATUSES = %w[pending uploading assembling complete aborted failed].freeze #: Array[String]

  before_create :set_id

  validates :filename, presence: true
  validates :total_chunks, presence: true, numericality: { greater_than: 0 }
  validates :status, inclusion: { in: STATUSES }

  #: () -> Pathname
  def chunks_dir
    Rails.root.join("tmp", "uploads", id.to_s)
  end

  #: (Integer chunk_number) -> Pathname
  def chunk_path(chunk_number)
    chunks_dir.join("chunk_#{chunk_number.to_s.rjust(6, '0')}")
  end

  #: () -> Array[Integer]
  def missing_chunks
    (1..total_chunks).reject { |n| File.exist?(chunk_path(n)) }
  end

  #: () -> bool
  def upload_complete?
    missing_chunks.empty?
  end

  #: () -> String?
  def assembled_file_path
    path = destination_path
    return nil if path.blank?
    File.join(path, filename)
  end

  private

  #: () -> void
  def set_id
    self.id ||= SecureRandom.uuid
  end
end
