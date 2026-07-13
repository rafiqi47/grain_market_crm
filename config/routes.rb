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

  # Admin Namespace
  namespace :admin do
    root to: "dashboard#index"

    resources :organizations do
      resources :users, only: [:new, :create, :index] do
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
    resources :supplier_ledgers, only: [:new, :create, :edit, :update, :destroy], controller: "suppliers/supplier_ledgers"
  end

  resources :products do
    resources :product_batches, only: [:new, :create, :edit, :update, :destroy]
  end

  resources :sales_orders, only: [:index, :show, :new, :create, :edit, :update, :destroy]

  resources :inventory_adjustments, only: [:index, :new, :create, :edit, :update] do
    post :reverse, on: :member
  end

  resources :inventory_alerts, only: [] do
    member do
      patch :mark_as_read
    end
  end

  resources :profits, only: [:index]
end
