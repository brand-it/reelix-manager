# rbs_inline: disabled
# frozen_string_literal: true

class TusUploadSession < ApplicationRecord
  self.primary_key = 'id'

  belongs_to :user, optional: true
  belongs_to :doorkeeper_token, class_name: 'Doorkeeper::AccessToken', optional: true
  belongs_to :video_blob, optional: true

  # Computed attributes from tus filesystem
  #: () -> Integer
  def upload_offset
    @upload_offset ||= compute_offset
  end

  #: () -> String
  def upload_status
    # pending, uploading, complete, aborted
    compute_status
  end

  #: () -> Time
  def expires_at
    # updated_at + tus expiration time (48 hours)
    updated_at + Tus::Server.opts[:expiration_time]
  end

  #: () -> bool
  def upload_complete?
    upload_length.positive? && upload_offset >= upload_length
  end

  #: () -> Integer
  def progress_percent
    return 0 unless upload_length.positive?

    ((upload_offset.to_f / upload_length) * 100).floor
  end

  #: () -> Integer
  def bytes_remaining
    [upload_length - upload_offset, 0].max
  end

  #: () -> Doorkeeper::Application?
  def device_application
    doorkeeper_token&.application
  end

  private

  #: () -> Integer
  def compute_offset
    info_path = tus_info_path
    return 0 unless info_path.exist?

    JSON.parse(info_path.binread)['Upload-Offset'].to_i
  rescue JSON::ParserError, Errno::ENOENT
    0
  end

  #: () -> String
  def compute_status
    return 'complete' if upload_complete?
    return 'aborted' unless tus_data_path.exist?

    upload_offset.zero? ? 'pending' : 'uploading'
  end

  #: () -> Pathname
  def tus_info_path
    Tus::Server.opts[:storage].directory.join("#{id}.info")
  end

  #: () -> Pathname
  def tus_data_path
    Tus::Server.opts[:storage].directory.join(id)
  end
end
