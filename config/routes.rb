Rails.application.routes.draw do
  resources :patients, only: [:index, :show]
  resources :plans, only: [:index, :show]
  resources :tiers, only: [:index, :show]
  resources :formularies, only: [:index, :show]
  resources :coverageplans, only: [:index, :show]
  resources :payerplans, only: [:index, :show]
  resources :compare, only: [:index]

  get "/home", to: "welcome#index"
  get "/dashboard", to: "dashboard#index"
  get "/login", to: "dashboard#login"
  get "/launch", to: "dashboard#launch"

  get "/bulk-publish", to: "bulk_publish#index", as: :bulk_publish
  get "/bulk-publish/preview", to: "bulk_publish#preview", as: :bulk_publish_preview

  get "up" => "rails/health#show", as: :rails_health_check

  root "welcome#index"
end
