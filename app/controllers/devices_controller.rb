class DevicesController < ApplicationController
  # @rbs @tokens: untyped

  #: () -> void
  def index
    user = current_user
    return unless user

    @tokens = if user.admin?
      Doorkeeper::AccessToken.all.newest.includes(:application, :user)
    else
      user.access_tokens.newest.includes(:application)
    end #: untyped
  end

  #: () -> void
  def destroy
    token = find_token
    if token
      token.revoke
      redirect_to devices_path, notice: "Device access revoked."
    else
      redirect_to devices_path, alert: "Device not found."
    end
  end

  private

  #: () -> untyped
  def find_token
    user = current_user
    return unless user

    if user.admin?
      Doorkeeper::AccessToken.find_by(id: params[:id])
    else
      user.access_tokens.find_by(id: params[:id])
    end
  end
end
