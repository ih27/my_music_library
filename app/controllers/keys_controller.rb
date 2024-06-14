class KeysController < ApplicationController
  before_action :set_key, only: [:show]

  def index
    @keys = Key.all
  end

  def show
    @playlists = Playlist.joins(tracks: :key).where(tracks: { key: @key }).distinct

    tracks = @key.tracks.includes(:artists, :key, :playlists)

    if params[:search].present?
      tracks = tracks.search(params[:search])
    end

    if params[:sort].present? && params[:direction].present?
      column = params[:sort]
      direction = params[:direction]

      case column
      when 'keys.name'
        tracks = tracks.sort_by { |track| natural_sort_key(track.key&.name) }
        tracks.reverse! if direction == 'desc'
      when 'artists.name'
        tracks = tracks.sort_by { |track| track.artists.map(&:name).join(", ") }
        tracks.reverse! if direction == 'desc'
      when 'playlists.name'
        tracks = tracks.sort_by { |track| natural_sort_key(track.playlists.map(&:name).join(", ")) }
        tracks.reverse! if direction == 'desc'
      else
        tracks = tracks.order("#{column} #{direction}")
      end
      # Use pagy_array for array results
      @pagy, @tracks = pagy_array(tracks)
    else
      # Use pagy for ActiveRecord::Relation
      @pagy, @tracks = pagy(tracks)
    end
  end

  private

  def set_key
    @key = Key.find(params[:id])
  end
end
