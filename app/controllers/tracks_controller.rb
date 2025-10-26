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

  def show
    @track = Track.includes(:artists, :key, :playlists).find(params[:id])
  end

  def upload_audio
    @track = Track.find(params[:id])
    if @track.update(audio_file_params)
      redirect_to tracks_path, notice: 'Audio file was successfully uploaded.'
    else
      redirect_to tracks_path, alert: 'Failed to upload audio file.'
    end
  end

  def compatible
    @track = Track.includes(:artists, :key).find(params[:id])
    bpm_range = params[:bpm_range].to_i if params[:bpm_range].present?

    compatible_tracks = @track.find_compatible(bpm_range: bpm_range)

    render json: {
      perfect: compatible_tracks[:perfect].as_json(include: { artists: { only: [:name] }, key: { only: [:name] } }),
      smooth: compatible_tracks[:smooth].as_json(include: { artists: { only: [:name] }, key: { only: [:name] } }),
      energy_boost: compatible_tracks[:energy_boost].as_json(include: { artists: { only: [:name] }, key: { only: [:name] } })
    }
  end

  private

  def audio_file_params
    params.require(:track).permit(:id, :audio_file)
  end

  def natural_sort_key(key)
    key.to_s.split(/(\d+)/).map { |e| e =~ /\d/ ? e.to_i : e }
  end
end
