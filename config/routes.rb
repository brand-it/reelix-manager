Rails.application.routes.draw do
  authenticate :user, ->(u) { u.admin? } do
    mount MissionControl::Jobs::Engine, at: "/jobs"
    mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  end

  post "/graphql", to: "graphql#execute"

  # tus resumable upload protocol endpoint.
  # Clients use POST /files to start, PATCH /files/:uid to send chunks,
  # HEAD /files/:uid to resume, DELETE /files/:uid to abort.
  mount Tus::Server => "/files"

  get "up" => "rails/health#show", as: :rails_health_check

  # First-run setup — creates the initial admin account.
  get  "setup", to: "setups#new",    as: :setup
  post "setup", to: "setups#create"

  # Devise authentication (sign in / sign out only; no registration).
  devise_for :users, skip: %i[registrations passwords confirmations]

  # OAuth 2.0 Device Authorization Grant (Doorkeeper).
  use_doorkeeper do
    skip_controllers :authorizations, :tokens_info
  end
  use_doorkeeper_device_authorization_grant

  # Devices management — list and revoke authorized Reelix clients.
  resources :devices, only: %i[index destroy] do
    collection do
      delete "grant/:id", action: :destroy_grant, as: :grant
    end
  end

  namespace :config do
    resource :video, only: %i[new create edit update]
  end

  # Static API documentation (public — explains how to authenticate).
  get "docs/api", to: "docs#api", as: :api_docs

  root "config/videos#new"
end
