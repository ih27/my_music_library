class TracksController < ApplicationController
  def index
    @tracks = Track.all.includes(:artists, :key, :playlists)

    if params[:sort].present? && params[:direction].present?
      column = params[:sort]
      direction = params[:direction]

      if column == 'keys.name'
        @tracks = @tracks.sort_by { |track| natural_sort_key(track.key&.name) }
        @tracks.reverse! if direction == 'desc'
      else
        @tracks = @tracks.order("#{column} #{direction}")
      end
    end

    @pagy, @tracks = pagy(@tracks) # Use pagy_array for array pagination
  end

  private

  def natural_sort_key(key)
    key.to_s.split(/(\d+)/).map { |e| e =~ /\d/ ? e.to_i : e }
  end
end
