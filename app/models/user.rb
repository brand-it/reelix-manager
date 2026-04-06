class User < ApplicationRecord
  # Only database authentication + remember me; no public registration, confirmable, or lockable.
  devise :database_authenticatable, :rememberable, :validatable

  has_many :access_tokens,
           class_name: "Doorkeeper::AccessToken",
           foreign_key: :resource_owner_id,
           dependent: :delete_all

  #: () -> bool
  def admin?
    admin
  end
end
