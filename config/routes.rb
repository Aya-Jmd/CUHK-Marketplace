Rails.application.routes.draw do
  get "conversations/index"
  get "conversations/show"
  devise_for :users
  resources :items
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # defines routes for user profiles, so user can view each other's profiles and edit their own.
  resources :users, only: [:show, :edit, :update]


  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "items#index"
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end
end
