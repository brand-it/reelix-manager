# frozen_string_literal: true

class AddDescriptionToOauthApplications < ActiveRecord::Migration[8.1]
  def change
    add_column :oauth_applications, :description, :text
  end
end
