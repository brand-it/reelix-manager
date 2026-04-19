# frozen_string_literal: true

class ApplicationController < ActionController::Base
  # Only allow modern browsers supporting webp images, web push, badges, import maps, CSS nesting, and CSS :has.
  allow_browser versions: :modern

  # Changes to the importmap will invalidate the etag for HTML responses
  stale_when_importmap_changes

  before_action :authenticate_or_setup!

  private

  # Redirects to first-run setup when no users exist; otherwise delegates to
  # Devise's standard authenticate_user! which redirects to the login page.
  # The setup page skips this entirely via skip_before_action in SetupsController.
  #: () -> void
  def authenticate_or_setup!
    if current_user.nil? && User.none?
      redirect_to setup_path
    else
      authenticate_user!
    end
  end
end
