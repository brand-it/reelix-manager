class ApplicationRecord < ActiveRecord::Base
  primary_abstract_class

  scope :newest, -> { order(created_at: :desc) } # steep:ignore NoMethod
  scope :oldest, -> { order(created_at: :asc) }  # steep:ignore NoMethod
end
