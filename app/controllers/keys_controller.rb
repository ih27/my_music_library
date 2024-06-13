class KeysController < ApplicationController
  before_action :set_key, only: [:show]

  def index
    @keys = Key.all
  end

  def show
    @playlists = Playlist.joins(tracks: :key).where(tracks: { key: @key }).distinct
  end

  private

  def set_key
    @key = Key.find(params[:id])
  end
end
