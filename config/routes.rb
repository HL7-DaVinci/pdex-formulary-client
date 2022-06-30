Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html

  root "welcome#index"

  resources :patients, only: [:index]
  resources :formularies, only: [:index, :show]
  resources :coverageplans, only: [:index, :show]
  resources :compare, only: [:index]

  get "/home", to: "welcome#index"
  get "/dashboard", to: "dashboard#index"
  get "/login", to: "dashboard#login"
  get "/launch", to: "dashboard#launch"
  get "patient-access", to: "patients#new"
  post "patient-access", to: "patients#create"
end
