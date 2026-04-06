class DocsController < ApplicationController
  # @rbs @applications: untyped
  # @rbs @default_app: untyped

  skip_before_action :authenticate_or_setup!

  #: () -> void
  def api
    @applications = Doorkeeper::Application.order(:name) #: untyped
    @default_app  = Doorkeeper::Application.find_by(name: "Reelix") || @applications.first #: untyped
  end
end
