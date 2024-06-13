class PlaylistsController < ApplicationController
  before_action :set_playlist, only: [:show, :destroy, :reorder_tracks]

  def new
    @playlist = Playlist.new
  end

  def create
    @playlist = Playlist.new
    if params[:playlist].present?
      Rails.logger.info "Params received: #{params.inspect}"
      file = playlist_params[:file]
      cover_art = playlist_params[:cover_art]

      if file.present?
        # Extract the name from the filename (without the extension)
        playlist_name = File.basename(file.original_filename, File.extname(file.original_filename))
        @playlist = Playlist.new(name: playlist_name)

        if cover_art.present?
          @playlist.cover_art.attach(cover_art)
        end

        importer = PlaylistImporter.new(@playlist, file)
        if importer.call
          attach_default_cover_art unless @playlist.cover_art.attached?
          redirect_to @playlist, notice: 'Playlist was successfully created.'
        else
          Rails.logger.info "Playlist import failed: Duplicate playlist detected or invalid data."
          flash.now[:alert] = 'Duplicate playlist detected or invalid data.'
          render :new, status: :unprocessable_entity
        end
      else
        flash.now[:alert] = 'File is required to create a playlist.'
        render :new, status: :unprocessable_entity
      end
    else
      flash.now[:alert] = 'File is required to create a playlist.'
      render :new, status: :unprocessable_entity
    end
  end

  def show
  end

  def index
    @playlists = Playlist.all
  end

  def destroy
    track_ids = @playlist.tracks.pluck(:id)
    artist_ids = Artist.joins(:tracks).where(tracks: { id: track_ids }).pluck(:id).uniq

    @playlist.destroy
    destroy_orphaned_tracks(track_ids)
    destroy_orphaned_artists(artist_ids)

    redirect_to playlists_url, notice: 'Playlist was successfully deleted.'
  end

  def reorder_tracks
    order = params[:order]

    ActiveRecord::Base.transaction do
      order.each do |item|
        playlist_track = PlaylistsTrack.find_by(playlist_id: @playlist.id, track_id: item[:id])
        if playlist_track
          playlist_track.update_column(:order, item[:order])
        else
          Rails.logger.error "Couldn't find PlaylistsTrack with playlist_id: #{@playlist.id} and track_id: #{item[:id]}"
          raise ActiveRecord::RecordNotFound, "Couldn't find PlaylistsTrack with playlist_id: #{@playlist.id} and track_id: #{item[:id]}"
        end
      end
    end

    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
  end

  def playlist_params
    params.require(:playlist).permit(:cover_art, :file)
  end

  def attach_default_cover_art
    @playlist.cover_art.attach(
      io: File.open(Rails.root.join('app', 'assets', 'images', 'default_cover_art.jpg')),
      filename: 'default_cover_art.jpg',
      content_type: 'image/jpg'
    )
  end

  def destroy_orphaned_tracks(track_ids)
    Rails.logger.info "Track IDs before destruction: #{track_ids}"
    track_ids.each do |track_id|
      track = Track.find_by(id: track_id)
      next unless track

      Rails.logger.info "Checking track: #{track.id} - #{track.name} with playlists count: #{track.playlists.count}"
      if track.playlists.empty?
        Rails.logger.info "Destroying track: #{track.id} - #{track.name}"
        track.destroy
      end
    end
  end

  def destroy_orphaned_artists(artist_ids)
    Rails.logger.info "Artist IDs before destruction: #{artist_ids}"
    artist_ids.each do |artist_id|
      artist = Artist.find_by(id: artist_id)
      next unless artist

      Rails.logger.info "Checking artist: #{artist.id} - #{artist.name} with tracks count: #{artist.tracks.count}"
      if artist.tracks.empty?
        Rails.logger.info "Destroying artist: #{artist.id} - #{artist.name}"
        artist.destroy
      end
    end
  end
end
