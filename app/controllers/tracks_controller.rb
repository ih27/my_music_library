class TracksController < ApplicationController
  def index
    tracks = Track.all.includes(:artists, :key, :playlists)

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

  def natural_sort_key(key)
    key.to_s.split(/(\d+)/).map { |e| e =~ /\d/ ? e.to_i : e }
  end
end
