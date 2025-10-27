# frozen_string_literal: true

Rails.application.routes.draw do
  resources :artists, only: %i[index show]
  resources :keys, only: %i[index show]
  resources :tracks, only: %i[index show] do
    member do
      post :upload_audio
      get :compatible
    end
  end

  resources :playlists, only: %i[new create show index destroy] do
    member do
      patch "reorder_tracks", to: "playlists#reorder_tracks", as: :reorder_tracks
    end
  end

  # Defines the root path route ("/")
  root "playlists#index"
end
