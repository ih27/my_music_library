class ArtistsController < ApplicationController
  before_action :set_artist, only: [:show]

  def index
    @artists = Artist.all.sort_by{|artist| [-artist.tracks.count, artist.name]}
  end

  def show
    @playlists = Playlist.joins(tracks: :artists).where(artists: { id: @artist.id }).distinct

    tracks = @artist.tracks.includes(:artists, :key, :playlists)

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

  def set_artist
    @artist = Artist.find(params[:id])
  end

  def natural_sort_key(key)
    key.to_s.split(/(\d+)/).map { |e| e =~ /\d/ ? e.to_i : e }
  end
end
