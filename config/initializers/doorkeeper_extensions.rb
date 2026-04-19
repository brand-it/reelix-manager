# frozen_string_literal: true

# Extend Doorkeeper models with the shared ordering scopes defined on ApplicationRecord.
Rails.application.config.after_initialize do
  Doorkeeper::AccessToken.scope :newest, -> { order(created_at: :desc) }
  Doorkeeper::AccessToken.scope :oldest, -> { order(created_at: :asc) }

  Doorkeeper::AccessToken.belongs_to :user,
                                     foreign_key: :resource_owner_id,
                                     inverse_of: :access_tokens,
                                     optional: true

  Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.belongs_to :user,
                                                               foreign_key: :resource_owner_id,
                                                               optional: true
end
