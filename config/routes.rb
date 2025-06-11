# frozen_string_literal: true

Rails.application.routes.draw do
  # Course management routes
  resources :courses do
    member do
      get :manage_invitations
      post :create_invitation
    end
  end

  # Course invitation routes
  resources :course_invitations, only: [ :show ], param: :token do
    member do
      post :join
      get :qr_code
    end
    collection do
      get :enter_code
      post :process_code
    end
  end
  mount Rswag::Ui::Engine => "/api-docs"
  mount Rswag::Api::Engine => "/api-docs"
  # API routes
  namespace :api, defaults: { format: :json } do
    # Version 1 routes (current)
    scope module: :v1, constraints: ApiVersionConstraint.new(version: 1, default: true) do
      # Authentication routes
      post "/login", to: "sessions#create"
      delete "/logout", to: "sessions#destroy"
      post "/signup", to: "registrations#create"

      # Profile routes
      resource :profile, only: [ :show, :update ]

      # Document endpoints
      resources :documents do
        member do
          post :finalize
          post :archive
        end
        collection do
          get :templates
        end
      end

      # Team endpoints
      resources :teams do
        resources :members, controller: "team_members", shallow: true
      end

      # Case endpoints
      resources :cases do
        resources :events, controller: "case_events", only: [ :index, :create ]
        resources :documents, controller: "case_documents", shallow: true
      end
    end

    # Version 2 routes (future)
    scope module: :v2, constraints: ApiVersionConstraint.new(version: 2) do
      # Add v2 routes here when needed
    end
  end

  # Devise routes with JWT
  devise_for :users, controllers: {
    omniauth_callbacks: "users/omniauth_callbacks",
    sessions: "users/sessions"
  }

  # Dashboard route
  get "dashboard", to: "dashboard#index", as: :dashboard

  # Health check endpoint
  get "up" => "rails/health#show", as: :rails_health_check
  get "/health", to: "health#check"

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  # Defines the root path route ("/")
  root "home#index"

  # Main resources
  resources :cases
  resources :teams

  # Static pages
  get "about", to: "pages#about"
  get "pricing", to: "pages#pricing"

  # User profile and settings
  resource :profile, only: [ :show, :update ]
  resource :settings, only: [ :show, :update ]

  # Admin routes
  namespace :admin do
    resources :licenses do
      member do
        patch :activate
        patch :deactivate
      end
      collection do
        post :validate_key
      end
    end

    resources :organizations do
      member do
        patch :activate
        patch :deactivate
      end
    end

    resources :users, except: [:new, :create]
  end

  # License management routes
  resource :license_status, only: [:show], controller: 'license_status' do
    member do
      post :activate_license
      post :request_trial
    end
  end

  # Admin impersonation routes
  scope :admin do
    post "impersonate/:id", to: "users#impersonate", as: :impersonate_user
    delete "stop_impersonation", to: "users#stop_impersonation", as: :stop_impersonation
    patch "enable_full_permissions", to: "users#enable_full_permissions", as: :enable_full_permissions
    patch "disable_full_permissions", to: "users#disable_full_permissions", as: :disable_full_permissions
  end
end
