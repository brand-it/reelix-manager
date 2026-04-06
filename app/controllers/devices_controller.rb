class DevicesController < ApplicationController
  def index
    @tokens = if current_user.admin?
      Doorkeeper::AccessToken.all.newest.includes(:application, :user)
    else
      current_user.access_tokens.newest.includes(:application)
    end
  end

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

  def find_token
    if current_user.admin?
      Doorkeeper::AccessToken.find_by(id: params[:id])
    else
      current_user.access_tokens.find_by(id: params[:id])
    end
  end
end
