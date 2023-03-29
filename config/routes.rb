Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  resources :patients, only: [:index, :show]
  resources :plans, only: [:index, :show]
  resources :tiers, only: [:index, :show]
  resources :formularies, only: [:index, :show]
  resources :coverageplans, only: [:index, :show]
  resources :payerplans, only: [:index]
  resources :compare, only: [:index]
  resources :formularyitems, only: [:index]

  get '/home', to: 'welcome#index'
  get '/dashboard', to: 'dashboard#index'
  get '/login', to: 'dashboard#login'
  get '/launch', to: 'dashboard#launch'

  root 'welcome#index'
end
