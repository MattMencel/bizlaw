# frozen_string_literal: true

Rails.application.routes.draw do
  # Quick fix for favicon requests during testing
  get '/favicon.ico', to: proc { [404, {}, []] }
  # Course management routes
  resources :courses do
    resources :teams, except: [:index]
    resources :cases
    member do
      get :manage_invitations
      post :create_invitation
      get :assign_students
      post :assign_student
      delete :remove_student
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

      # Context switching routes
      resource :context, only: [], controller: 'context' do
        get :current
        patch :switch_case
        patch :switch_team
        get :search
        get :available
      end

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
        
        # Case materials management
        resources :case_materials, only: [ :index, :show, :create, :update, :destroy ] do
          member do
            get :download
            post :annotate
          end
          collection do
            get :search
            get :categories
          end
        end
        
        # Simulation endpoints
        resources :negotiation_rounds, only: [ :index, :show, :create, :update ]
        
        # Simulation status endpoints
        resource :simulation_status, only: [ :show ], controller: "simulation_status" do
          get :client_mood
          get :pressure_status
          get :negotiation_history
          get :events_feed
        end
        
        # Argument quality scoring endpoints (instructor only)
        resources :argument_quality, only: [ :index, :show, :update ] do
          collection do
            get :rubric
          end
        end
        
        # Evidence release schedule endpoints
        resources :evidence_releases, only: [ :index, :show, :create ] do
          member do
            put :approve
            put :deny
          end
          collection do
            get :schedule
            post :schedule_automatic
          end
        end
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
  resources :terms
  resources :cases, only: [:index] do
    # Evidence vault interface
    resources :evidence_vault, only: [:index, :show] do
      member do
        post :annotate
        put :update_tags
      end
      collection do
        get :search
        post :bundles, action: :create_bundle
      end
    end
    
    # Negotiation interface
    resources :negotiations, only: [:index, :show, :new, :create, :edit, :update] do
      member do
        get :submit_offer
        post :create_offer
        get :counter_offer
        post :submit_counter_offer
        get :client_consultation
        post :consult_client
      end
      collection do
        get :history
        get :templates
        get :calculator
      end
    end
  end
  resources :teams, only: [:index, :show]

  # Static pages
  get "about", to: "pages#about"
  get "pricing", to: "pages#pricing"

  # User profile and settings
  resource :profile, only: [ :show, :update ]
  resource :settings, only: [ :show, :update ]

  # Invitation routes
  resources :invitations, except: [:show] do
    member do
      patch :resend
      patch :revoke
    end
    collection do
      get :shareable, to: 'invitations#new_shareable'
      post :create_shareable
    end
  end

  # Invitation acceptance routes
  get 'accept/:token', to: 'invitation_acceptance#show', as: :accept_invitation
  post 'accept/:token', to: 'invitation_acceptance#accept', as: :process_invitation
  get 'join/:token', to: 'invitation_acceptance#show_shareable', as: :accept_shareable_invitation
  post 'join/:token', to: 'invitation_acceptance#accept_shareable', as: :process_shareable_invitation

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

    resources :users, except: [:new, :create] do
      member do
        patch :assign_org_admin
        patch :remove_org_admin
      end
    end
  end

  # License management routes
  resource :license_status, only: [:show], controller: 'license_status' do
    member do
      post :activate_license
      post :request_trial
    end
  end

  # Scoring Dashboard routes
  resource :scoring_dashboard, only: [:show] do
    get :performance_data
    get :trends
    get :class_analytics
    post :export_report
    patch :update_score
  end
  
  # Alias for instructor dashboard
  get "instructor_scoring_dashboard", to: "scoring_dashboard#index"

  # Admin impersonation routes
  scope :admin do
    post "impersonate/:id", to: "users#impersonate", as: :impersonate_user
    delete "stop_impersonation", to: "users#stop_impersonation", as: :stop_impersonation
    patch "enable_full_permissions", to: "users#enable_full_permissions", as: :enable_full_permissions
    patch "disable_full_permissions", to: "users#disable_full_permissions", as: :disable_full_permissions
  end
end
