class DevicesController < ApplicationController
  # @rbs @tokens: untyped
  # @rbs @device_grants: untyped

  #: () -> void
  def index
    user = current_user
    return unless user

    @tokens = if user.admin?
      Doorkeeper::AccessToken.all.newest.includes(:application, :user)
    else
      user.access_tokens.newest.includes(:application)
    end #: untyped

    @device_grants = if user.admin?
      Doorkeeper::DeviceAuthorizationGrant::DeviceGrant
        .where.not(resource_owner_id: nil)
        .order(created_at: :desc)
        .includes(:application)
    else
      Doorkeeper::DeviceAuthorizationGrant::DeviceGrant
        .where(resource_owner_id: user.id)
        .order(created_at: :desc)
        .includes(:application)
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

  #: () -> void
  def destroy_grant
    grant = find_grant
    if grant
      grant.destroy
      redirect_to devices_path, notice: "Pending device authorization cancelled."
    else
      redirect_to devices_path, alert: "Pending device not found."
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

  #: () -> untyped
  def find_grant
    user = current_user
    return unless user

    if user.admin?
      Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.find_by(id: params[:id])
    else
      Doorkeeper::DeviceAuthorizationGrant::DeviceGrant.find_by(
        id: params[:id],
        resource_owner_id: user.id
      )
    end
  end
end
