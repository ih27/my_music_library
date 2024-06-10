class PlaylistsController < ApplicationController
  before_action :set_playlist, only: [:show, :destroy, :reorder_tracks]

  def new
    @playlist = Playlist.new
  end

  def create
    Rails.logger.info "Params received: #{params.inspect}"
    @playlist = Playlist.new(playlist_params.except(:file))

    file = params[:playlist][:file]
    if file.present?
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
      # TODO: what if playlist file is not uploaded? deal with it later, keep empty for now
    end
  end

  def show
  end

  def index
    @playlists = Playlist.all
  end

  def destroy
    @playlist.destroy
    redirect_to playlists_url, notice: 'Playlist was successfully deleted.'
  end

  def reorder_tracks
    order = params[:order]
    ActiveRecord::Base.transaction do
      order.each do |item|
        playlist_track = PlaylistsTrack.find(item[:id])
        playlist_track.update_column(:order, nil)  # Temporarily set to nil to avoid uniqueness conflict
      end

      order.each do |item|
        playlist_track = PlaylistsTrack.find(item[:id])
        playlist_track.update!(order: item[:order])
      end
    end
    head :ok
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  private

  def set_playlist
    @playlist = Playlist.find(params[:id])
  end

  def playlist_params
    params.require(:playlist).permit(:name, :cover_art, :file)
  end

  def attach_default_cover_art
    @playlist.cover_art.attach(
      io: File.open(Rails.root.join('app', 'assets', 'images', 'default_cover_art.jpg')),
      filename: 'default_cover_art.jpg',
      content_type: 'image/jpg'
    )
  end
end
