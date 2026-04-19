# frozen_string_literal: true

# Patches Doorkeeper::ApplicationsController after it is fully loaded by the gem.
# Using config.to_prepare ensures this runs:
#   - once on each request in development (after Zeitwerk reloads)
#   - once at boot in test / production
# The doorkeeper/admin layout is overridden via app/views/layouts/doorkeeper/admin.html.erb.
Rails.application.config.to_prepare do
  Doorkeeper::ApplicationsController.class_eval do
    private

    def application_params
      # uid (Client ID) is only permitted on create — excluded on update to prevent changes.
      permitted = if action_name == 'create'
                    [:name, :description, :redirect_uri, :confidential, :uid, { scopes: [] }]
                  else
                    [:name, :description, :redirect_uri, :confidential, { scopes: [] }]
                  end
      raw = params.require(:doorkeeper_application).permit(*permitted)
      raw[:scopes] = Array(raw[:scopes]).reject(&:blank?).join(' ')
      raw
    end
  end
end
