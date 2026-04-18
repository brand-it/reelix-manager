# frozen_string_literal: true

class DocsController < ApplicationController
  # @rbs @applications: ActiveRecord::Relation
  # @rbs @default_app: Doorkeeper::Application?

  skip_before_action :authenticate_or_setup!

  #: () -> void
  def api
    @applications = Doorkeeper::Application.order(:name) #: ActiveRecord::Relation
    @default_app  = Doorkeeper::Application.find_by(name: 'Reelix') || @applications.first #: Doorkeeper::Application?
  end
end
