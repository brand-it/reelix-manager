# frozen_string_literal: true

class SetupsController < ApplicationController
  # @rbs @user: User?

  # Skip all auth checks — this is the unauthenticated first-run bootstrap page.
  skip_before_action :authenticate_or_setup!

  # GET /setup
  #: () -> void
  def new
    # If any user exists, this page must not be accessible.
    redirect_to(root_path) and return if User.any?

    @user = User.new #: User
  end

  # POST /setup
  #: () -> void
  def create
    # Double-check server-side — guards against race conditions and direct POST attacks.
    if User.any?
      redirect_to root_path, alert: 'Setup is already complete.'
      return
    end

    @user = User.new(setup_params.merge(admin: true)) #: User
    user = @user #: User

    if user.save
      sign_in(:user, user)
      redirect_to root_path, notice: 'Admin account created. Welcome to Reelix Manager!'
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  #: () -> ActionController::Parameters
  def setup_params
    params.require(:user).permit(:email, :password, :password_confirmation)
  end
end
