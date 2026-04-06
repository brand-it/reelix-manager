class DocsController < ApplicationController
  skip_before_action :authenticate_or_setup!

  def api
    @applications = Doorkeeper::Application.order(:name)
    @default_app  = Doorkeeper::Application.find_by(name: "Reelix") || @applications.first
  end
end
