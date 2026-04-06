class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :newest, -> { order(created_at: :desc) }
  scope :oldest, -> { order(created_at: :asc) }
end
