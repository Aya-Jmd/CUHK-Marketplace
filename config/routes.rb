Rails.application.routes.draw do
  # Health check for container and deployment probes.
  get "up" => "rails/health#show", as: :rails_health_check

  # Authentication and user-facing profile pages.
  devise_for :users, controllers: { sessions: "users/sessions", registrations: "users/registrations" }
  resources :users, only: [ :show ]
  get "/dashboard", to: "dashboards#show", as: :dashboard
  get "/profile", to: "dashboards#edit", as: :profile
  patch "/profile", to: "dashboards#update"

  # Marketplace browsing, search, and listing creation.
  root "items#index"

  get "/search", to: "search#index", as: :search
  resource :currency, only: [ :update ]

  get "analytics", to: "dashboards#category_prices", as: :analytics

  resources :items do
    resources :offers, only: [ :new, :create ]
    resources :item_reports, only: [ :create ]
    resource :favorite, only: [ :create, :destroy ]
  end

  # Offer lifecycle after a listing thread has been created.
  resources :offers, only: [ :index, :show, :update, :destroy ] do
    member do
      patch :accept
      patch :decline
      patch :complete
      patch :cancel
    end
  end

  # Messaging and notification flows.
  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
  end

  resources :notifications, only: [ :index ] do
    member do
      patch :mark_as_read
    end

    collection do
      patch :mark_all_as_read
    end
  end

  # Admin management and setup flows.
  namespace :admin do
    root to: "dashboard#index"

    post "invite", to: "dashboard#invite", as: :invite
    post "reveal_invites", to: "dashboard#reveal_invites", as: :reveal_invites
    resource :college_rules, only: [ :update ]

    resources :users, only: [] do
      member do
        patch :ban
        patch :unban
      end
    end

    resources :item_reports, only: [] do
      member do
        patch :ignore
        patch :delete_item
      end
    end

    resource :setup, only: [ :edit, :update ]
  end

  # Lightweight JSON endpoints used by the frontend.
  namespace :api do
    get "locations/all", to: "locations#all"
    get "locations/closest", to: "locations#closest"
    get "locations/:key", to: "locations#show"
  end

  # Keep the custom 404 page for app routes without intercepting Active Storage.
  match "*unmatched",
    to: "errors#not_found",
    via: :all,
    constraints: lambda { |request|
      !request.path.start_with?("/rails/active_storage")
    }
end
