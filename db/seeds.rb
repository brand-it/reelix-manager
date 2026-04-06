# This file should ensure the existence of records required to run the application in every environment (production,
# development, test). The code here should be idempotent so that it can be executed at any point in every environment.
# The data can then be loaded with the bin/rails db:seed command (or created alongside the database with db:setup).

# Create the Reelix client OAuth application (public client — no secret).
# This gives Reelix media clients a known client_id to use for the device flow.
Doorkeeper::Application.find_or_create_by!(uid: "reelix-client") do |app|
  app.name          = "Reelix"
  app.redirect_uri  = ""
  app.scopes        = "all"
  app.confidential  = false
end

puts "Doorkeeper application 'Reelix' ready (client_id: reelix-client)"
