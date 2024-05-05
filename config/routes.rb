Rails.application.routes.draw do
  resource :session, only: %i[new create destroy]
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/*
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest

  # Defines the root path route ("/")


  resources :chats, only: %i[index show] do
    resources :messages, only: %i[create]
  end

  get "/events/sse" => "events#sse"

  root "chats#index"
end
