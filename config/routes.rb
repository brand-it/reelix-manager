Rails.application.routes.draw do
  get "up" => "rails/health#show", as: :rails_health_check

  namespace :config do
    resource :video, only: %i[new create edit update]
  end

  root "config/videos#new"
end
