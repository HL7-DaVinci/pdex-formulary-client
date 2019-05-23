Rails.application.routes.draw do
  # For details on the DSL available within this file, see http://guides.rubyonrails.org/routing.html
  root 'welcome#index'

  resources :plans, only: [:index, :show]
  resources :tiers, only: [:index, :show]
  resources :formularies, only: [:index, :show]
end
