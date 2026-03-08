Rails.application.routes.draw do
  mount GraphiQL::Rails::Engine, at: "/graphiql", graphql_path: "/graphql"
  post "/graphql", to: "graphql#execute"

  # tus resumable upload protocol endpoint.
  # Clients use POST /files to start, PATCH /files/:uid to send chunks,
  # HEAD /files/:uid to resume, DELETE /files/:uid to abort.
  mount Tus::Server => "/files"

  get "up" => "rails/health#show", as: :rails_health_check

  namespace :config do
    resource :video, only: %i[new create edit update]
  end

  root "config/videos#new"
end
