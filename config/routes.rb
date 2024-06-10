Rails.application.routes.draw do
  resources :articles
  # Define your application routes per the DSL in https://guides.rubyonrails.org/routing.html

  # Reveal health status on /up that returns 200 if the app boots with no exceptions, otherwise 500.
  # Can be used by load balancers and uptime monitors to verify that the app is live.
  get "up" => "rails/health#show", as: :rails_health_check

  resources :playlists, only: [:new, :create, :show, :index, :destroy] do
    member do
      patch 'reorder_tracks', to: 'playlists#reorder_tracks', as: :reorder_tracks
    end
  end

  # Defines the root path route ("/")
  root "playlists#index"
end
