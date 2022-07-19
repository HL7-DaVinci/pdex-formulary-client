Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
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
  get "/server-metadata", to: "dashboard#server_metadata"
  get "/registration", to: "dashboard#registration"
  get "bulkdata/index"
  get "bulkdata/export"
  get "bulkdata/pollexport"
  get "bulkdata/cancel"

  root "welcome#index"
end
