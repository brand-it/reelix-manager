# frozen_string_literal: true

module Types
  class UploadSessionType < Types::BaseObject
    field :id, ID, null: false
    field :filename, String, null: false
    field :status, String, null: false
    field :upload_length, GraphQL::Types::BigInt, null: false, description: 'Total expected bytes for the tus upload'
    field :upload_offset, GraphQL::Types::BigInt, null: false, description: 'Bytes currently stored on the server'
    field :bytes_remaining, GraphQL::Types::BigInt, null: false
    field :progress_percent, Integer, null: false
    field :upload_complete, Boolean, null: false
    field :created_at, String, null: false
    field :updated_at, String, null: false
    field :expires_at, String, null: false,
                               description: 'When the incomplete tus upload will expire if no more data is sent'
    field :device_name, String, null: true, description: 'OAuth application name'
    field :user_email, String, null: true, description: 'Email of user who uploaded'

    #: () -> String
    def status = object.upload_status

    #: () -> bool
    def upload_complete? = object.upload_complete?

    #: () -> Integer
    def bytes_remaining
      [object.upload_length - object.upload_offset, 0].max
    end

    #: () -> Integer
    def progress_percent
      return 0 unless object.upload_length.positive?

      ((object.upload_offset.to_f / object.upload_length) * 100).floor
    end

    #: () -> String
    def created_at = object.created_at.iso8601

    #: () -> String
    def updated_at = object.updated_at.iso8601

    #: () -> String
    def expires_at = object.expires_at.iso8601

    #: () -> String?
    def device_name = object.doorkeeper_token&.application&.name

    #: () -> String?
    def user_email = object.user&.email
  end
end
