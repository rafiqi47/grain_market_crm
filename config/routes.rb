Rails.application.routes.draw do
  get "dashboard/index"
  get "home/index"
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  # Render dynamic PWA files from app/views/pwa/* (remember to link manifest in application.html.erb)
  # get "manifest" => "rails/pwa#manifest", as: :pwa_manifest
  # get "service-worker" => "rails/pwa#service_worker", as: :pwa_service_worker

  devise_for :users, controllers: {
    passwords: 'users/passwords'
  }

  authenticate :user, ->(user) { user.super_admin? } do
    mount MissionControl::Jobs::Engine, at: "/admin/jobs"
  end

  # Admin Namespace
  namespace :admin do
    root to: "dashboard#index"

    resources :organizations do
      resources :users, only: [:new, :create, :index, :update] do
        member do
          patch :toggle_subscription
        end
      end
    end
  end

  # Defines the root path route ("/")
  root "home#index" # Public Landing Page (no authentication required)

  get "dashboard", to: "dashboard#index", as: :dashboard

  resources :suppliers, only: [:index, :show, :new, :create, :edit, :update] do
    member do
      get :products_for_adjustment
    end
    resources :supplier_ledgers, only: [:new, :create, :edit, :update, :destroy], controller: "suppliers/supplier_ledgers"
    resources :purchases, only: [:new, :create], controller: "suppliers/purchases"
    resources :products, only: [:show, :edit, :update, :destroy], controller: "suppliers/products" do
      collection do
        post :quick_create
      end
      member do
        get :batches_for_adjustment
      end
    end
  end

  resources :farmers, only: [:index, :show, :new, :create, :edit, :update] do
    member do
      get :khata_statement
    end

    resources :crop_purchases, only: [:new, :create, :index], controller: "farmers/crop_purchases"

    resources :khata_cycles, only: [:show] do
      member do
        post :close
      end
      resources :khata_transactions, only: [:new, :create, :edit, :update, :destroy], controller: "farmers/khata_transactions"
    end
  end

  resources :crops, only: [:index, :show, :new, :create, :edit, :update]

  resources :trading_partners, only: [:index, :show, :new, :create, :edit, :update] do
    member do
      get :statement
    end

    resources :trading_partner_ledgers, only: [:new, :create, :edit, :update, :destroy], controller: "trading_partners/trading_partner_ledgers"
    resources :crop_sales, only: [:new, :create], controller: "trading_partners/crop_sales"
  end

  resources :products, only: [] do
    resources :product_batches, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :sales_orders, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  resources :inventory_adjustments, only: [:index, :new, :create, :edit, :update] do
    post :reverse, on: :member
  end

  resources :inventory_alerts, only: [:index] do
    member do
      patch :mark_as_read
    end
  end

  resources :profits, only: [:index]

  resource :organization_settings, only: [:edit, :update]

  resources :expirations, only: [:index] do
    member do
      get :detail
    end
  end
end
