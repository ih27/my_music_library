class ArtistsController < ApplicationController
  before_action :set_artist, only: [:show]
  def index
    @artists = Artist.all
  end

  def show
    @playlists = Playlist.joins(tracks: :artists).where(artists: { id: @artist.id }).distinct
  end

  private

  def set_artist
    @artist = Artist.find(params[:id])
  end
end
