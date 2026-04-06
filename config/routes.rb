Rails.application.routes.draw do
  get "search/index"
  get "conversations/index"
  get "conversations/show"
  devise_for :users, controllers: { sessions: "users/sessions" }
  resources :items do
    resources :offers, only: [:create]
  end
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # The main Control Room
  get 'dashboard', to: 'dashboards#index', as: :dashboard
  
  # Transaction Flow Routes
  resources :offers, only: [] do
    member do
      patch :accept
      patch :decline
      patch :complete
      patch :cancel  # NEW: For when the buyer ghosts!
    end
  end
  
  # defines routes for user profiles, so user can view each other's profiles and edit their own.
  resources :users, only: [:show, :edit, :update]

  get 'profile', to: 'users#edit', as: :profile

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check


  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker


  # routes for price analytics dashboards
  get "dashboard/category_prices", 
  to: "dashboards#category_prices",
  # useful for links, eg : <%= link_to "Dashboard", category_prices_dashboard_path %>
  as: :category_prices_dashboard 


  # routes for currency
  resource :currency, only: [:update]
  

  get '/search', to: 'search#index', as: :search
  resources :conversations, only: [:index, :show, :create] do
    resources :messages, only: [:create]
  end
  
  # API for location lookup
  namespace :api do
    # 1. Put static routes first
    get 'locations/all', to: 'locations#all'
    get 'locations/closest', to: 'locations#closest'
    
    # 2. Put the dynamic ID/Key route LAST
    get 'locations/:key', to: 'locations#show'
  end

  # Defines the root path route ("/")
  root "items#index"
  # config/routes.rb
  namespace :admin do
    get 'dashboard', to: 'dashboard#index'
    post 'dashboard/invite', to: 'dashboard#invite', as: :invite_admin
    
    get 'setup', to: 'setups#edit', as: :first_time_setup
    patch 'setup', to: 'setups#update'
  end
end
