# frozen_string_literal: true

class DjSetsController < ApplicationController
  before_action :set_dj_set, only: %i[show edit update destroy duplicate
                                      export convert_to_playlist add_tracks
                                      remove_track remove_tracks reorder_tracks]

  # GET /dj_sets
  def index
    @dj_sets = DjSet.includes(:tracks).order(sort_column => sort_direction)
  end

  # GET /dj_sets/:id
  def show
    @tracks = @dj_set.ordered_tracks.includes(:artists, :key)
    @harmonic_analysis = @dj_set.harmonic_analysis
  end

  # GET /dj_sets/new
  def new
    @dj_set = DjSet.new
  end

  # POST /dj_sets
  def create
    @dj_set = DjSet.new(dj_set_params)

    if @dj_set.save
      # Add tracks if coming from track selection
      add_selected_tracks_to_set if params[:track_ids].present?
      redirect_to @dj_set, notice: "#{@dj_set.name} created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /dj_sets/:id/edit
  def edit
  end

  # PATCH /dj_sets/:id
  def update
    if @dj_set.update(dj_set_params)
      redirect_to @dj_set, notice: "Set updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /dj_sets/:id
  def destroy
    name = @dj_set.name
    @dj_set.destroy
    redirect_to dj_sets_path, notice: "#{name} deleted"
  end

  # POST /dj_sets/:id/add_tracks
  def add_tracks
    track_ids = params[:track_ids].compact_blank

    # Add tracks with temporary order values
    track_ids.each_with_index do |track_id, index|
      next_order = (@dj_set.dj_sets_tracks.maximum(:order) || 0) + index + 1
      @dj_set.dj_sets_tracks.create(track_id: track_id, order: next_order)
    end

    resequence_tracks
    @dj_set.touch

    redirect_to @dj_set, notice: "#{track_ids.size} track(s) added"
  end

  # DELETE /dj_sets/:id/remove_track/:track_id
  def remove_track
    @dj_set.dj_sets_tracks.find_by(track_id: params[:track_id])&.destroy

    resequence_tracks
    @dj_set.touch

    redirect_to @dj_set, notice: "Track removed"
  end

  # DELETE /dj_sets/:id/remove_tracks
  def remove_tracks
    track_ids = params[:track_ids].compact_blank

    track_ids.each do |track_id|
      @dj_set.dj_sets_tracks.find_by(track_id: track_id)&.destroy
    end

    resequence_tracks
    @dj_set.touch

    redirect_to @dj_set, notice: "#{track_ids.size} track(s) removed"
  end

  # POST /dj_sets/:id/reorder_tracks
  def reorder_tracks
    order = params[:order]

    ActiveRecord::Base.transaction do
      order.each do |item|
        dj_sets_track = DjSetsTrack.find_by(dj_set_id: @dj_set.id, track_id: item[:id])
        if dj_sets_track
          dj_sets_track.update_column(:order, item[:order])
        else
          Rails.logger.error "Couldn't find DjSetsTrack with dj_set_id: #{@dj_set.id} and track_id: #{item[:id]}"
          raise ActiveRecord::RecordNotFound,
                "Couldn't find DjSetsTrack with dj_set_id: #{@dj_set.id} and track_id: #{item[:id]}"
        end
      end
      # Touch the parent to update updated_at timestamp
      @dj_set.touch
    end

    # Return updated harmonic score for AJAX response
    @dj_set.reload
    render json: {
      success: true,
      harmonic_score: @dj_set.harmonic_flow_score
    }
  rescue ActiveRecord::RecordInvalid => e
    render json: { error: e.message }, status: :unprocessable_entity
  rescue ActiveRecord::RecordNotFound => e
    render json: { error: e.message }, status: :not_found
  end

  # POST /dj_sets/:id/duplicate
  def duplicate
    new_set = @dj_set.duplicate(new_name: params[:name] || "#{@dj_set.name} (Copy)")
    redirect_to new_set, notice: "Duplicated as #{new_set.name}"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @dj_set, alert: "Error duplicating set: #{e.message}"
  end

  # GET /dj_sets/:id/export
  def export
    content = @dj_set.export_to_file
    filename = "#{@dj_set.name.parameterize}_#{Time.current.to_i}.txt"

    send_data content,
              filename: filename,
              type: "text/plain",
              disposition: "attachment"
  end

  # POST /dj_sets/:id/convert_to_playlist
  def convert_to_playlist
    playlist = @dj_set.convert_to_playlist(
      name: params[:name],
      cover_art: params[:cover_art]
    )

    @dj_set.destroy if params[:delete_set] == "1"

    redirect_to playlist, notice: "Converted to playlist: #{playlist.name}"
  rescue StandardError => e
    redirect_to @dj_set, alert: "Error converting: #{e.message}"
  end

  private

  def set_dj_set
    @dj_set = DjSet.find(params[:id])
  end

  def dj_set_params
    params.expect(dj_set: %i[name description])
  end

  def sort_column
    %w[name updated_at].include?(params[:sort]) ? params[:sort] : "updated_at"
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : "desc"
  end

  def add_selected_tracks_to_set
    track_ids = params[:track_ids].compact_blank

    track_ids.each_with_index do |track_id, index|
      @dj_set.dj_sets_tracks.create(track_id: track_id, order: index + 1)
    end
  end

  # Resequence all tracks in the set to ensure sequential order (1, 2, 3, ...)
  # This ensures no gaps in track numbers after add/remove operations
  def resequence_tracks
    @dj_set.dj_sets_tracks.order(:order).each_with_index do |dj_sets_track, index|
      dj_sets_track.update_column(:order, index + 1)
    end
  end
end
