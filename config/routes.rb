Rails.application.routes.draw do
  # Reveal health status on /up
  get "up" => "rails/health#show", as: :rails_health_check

  # -----------------------------------------------------------------------
  # 1. AUTHENTICATION & PROFILES
  # -----------------------------------------------------------------------
  devise_for :users, controllers: { sessions: "users/sessions" }

  # Public user profiles (e.g., viewing a seller's rating/items)
  resources :users, only: [ :show ]

  # Private user dashboard (The logged-in user's management area)
  resource :profile, only: [ :show, :edit, :update ] do
    collection do
      get :my_items   # Page to manage their active listings
      get :my_offers  # Page to track offers they've made/received
    end
  end

  # -----------------------------------------------------------------------
  # 2. PUBLIC MARKETPLACE & TENANCY
  # -----------------------------------------------------------------------
  # Defines the root path route ("/")
  root "items#index"

  get "/search", to: "search#index", as: :search
  resource :currency, only: [ :update ]

  get "analytics", to: "dashboards#category_prices", as: :analytics

  # Items and the initial Offer creation are deeply nested.
  # This ensures an offer is always tied to an item.
  resources :items do
    resources :offers, only: [ :new, :create ]
  end

  # -----------------------------------------------------------------------
  # 3. TRANSACTION HUB (The Lifecycle)
  # -----------------------------------------------------------------------
  # Once an offer exists, we use "Shallow Routing" to manage its state.
  # We don't need the item_id in the URL to accept/decline an offer.
  resources :offers, only: [ :index, :show ] do
    member do
      patch :accept
      patch :decline
      patch :complete
      patch :cancel # For when the buyer ghosts!
    end
  end

  # -----------------------------------------------------------------------
  # 4. N-1 FEATURES (Communication & Alerts)
  # -----------------------------------------------------------------------
  resources :conversations, only: [ :index, :show, :create ] do
    resources :messages, only: [ :create ]
  end

  # Preparing for the Real-Time Notification system from the proposal
  resources :notifications, only: [ :index ] do
    # for a specific item in notification table
    member do 
      patch :mark_as_read
    end

    # for all items in notifications table
    collection do
      patch :mark_all_as_read
      get :all # view all notifications in a separate page (all VS unread notifications)
    end
  end

  # -----------------------------------------------------------------------
  # 5. ADMIN & ANALYTICS ZONE
  # -----------------------------------------------------------------------
  # Groups all admin features cleanly under the /admin/ path
  namespace :admin do
    root to: "dashboard#index" # Renders at /admin

    get "category_prices", to: "dashboard#category_prices", as: :category_prices
    post "invite", to: "dashboard#invite", as: :invite

    resource :setup, only: [ :edit, :update ]
  end

  # -----------------------------------------------------------------------
  # 6. INTERNAL APIs (AJAX & Maps)
  # -----------------------------------------------------------------------
  namespace :api do
    get "locations/all", to: "locations#all"
    get "locations/closest", to: "locations#closest"
    get "locations/:key", to: "locations#show"
  end
end
