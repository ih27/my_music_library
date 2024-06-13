class TracksController < ApplicationController
  def index
    @tracks = Track.all.includes(:artists, :key, :playlists)
  end
end
