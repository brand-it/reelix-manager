# frozen_string_literal: true

# Scope metadata used in the Doorkeeper applications form pick list.
# Keys match the optional_scopes defined in config/initializers/doorkeeper.rb.
DOORKEEPER_SCOPES = {
  "all"    => "Unrestricted — full access to every operation (use with caution)",
  "search" => "Search — query movies and TV shows via TMDB (searchMulti, node, nodes)",
  "upload" => "Upload — finalize file uploads (finalizeUpload mutation)"
}.freeze

# Ensure the default Reelix OAuth application exists on every boot and stays
# up to date. Looks up by stable uid so name changes and re-seeds don't create
# duplicates. This runs after the framework is initialized, so it is safe to
# use ActiveRecord. The guard prevents errors during db:create / db:migrate
# when the table does not exist yet.
Rails.application.config.after_initialize do
  next unless ActiveRecord::Base.connection.table_exists?("oauth_applications")

  app = Doorkeeper::Application.find_or_initialize_by(uid: "reelix-client")
  app.assign_attributes(
    name:         "Reelix",
    redirect_uri: "",
    scopes:       "all",
    confidential: false,
    description:  "Default Reelix client application. Used by Reelix devices to authenticate via the OAuth 2.0 Device Authorization Grant flow."
  )
  app.save!

  Rails.logger.info "Doorkeeper: Reelix application provisioned."
rescue => e
  Rails.logger.warn "Doorkeeper: could not provision Reelix application — #{e.message}"
end
