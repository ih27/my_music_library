Rails.application.routes.draw do
  resources :artists, only: [:index, :show]
  resources :keys, only: [:index, :show]
  resources :tracks, only: [:index]

  resources :playlists, only: [:new, :create, :show, :index, :destroy] do
    member do
      patch 'reorder_tracks', to: 'playlists#reorder_tracks', as: :reorder_tracks
    end
  end

  # Defines the root path route ("/")
  root "playlists#index"
end
