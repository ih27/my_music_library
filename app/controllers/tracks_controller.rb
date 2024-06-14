class TracksController < ApplicationController
  def index
    tracks = Track.all.includes(:artists, :key, :playlists)

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

  def upload_audio
    @track = Track.find(params[:id])
    if @track.update(audio_file_params)
      redirect_to tracks_path, notice: 'Audio file was successfully uploaded.'
    else
      redirect_to tracks_path, alert: 'Failed to upload audio file.'
    end
  end

  private

  def audio_file_params
    params.require(:track).permit(:audio_file)
  end

  def natural_sort_key(key)
    key.to_s.split(/(\d+)/).map { |e| e =~ /\d/ ? e.to_i : e }
  end
end
