# frozen_string_literal: true

# rubocop:disable Metrics/ClassLength
class DjSetsController < ApplicationController
  before_action :set_dj_set, only: %i[show edit update destroy duplicate
                                      export convert_to_playlist add_tracks
                                      remove_track remove_tracks reorder_tracks
                                      import_tracks optimize revert_optimization]

  # GET /dj_sets
  def index
    @dj_sets = DjSet.includes(:tracks).order(sort_column => sort_direction)
  end

  # GET /dj_sets/:id
  def show
    @tracks = @dj_set.ordered_tracks.includes(:artists, :key)
    @harmonic_analysis = @dj_set.harmonic_analysis
    @detailed_analysis = @dj_set.detailed_harmonic_analysis
  end

  # GET /dj_sets/new
  def new
    @dj_set = DjSet.new
  end

  # POST /dj_sets
  def create
    file = params.dig(:dj_set, :file)

    # Mode 1: Import from file
    if file.present?
      # Extract name from filename (without extension)
      set_name = File.basename(file.original_filename, File.extname(file.original_filename))
      @dj_set = DjSet.new(name: set_name, description: dj_set_params[:description])

      importer = DjSetImporter.new(@dj_set, file)
      if importer.call
        redirect_to @dj_set, notice: "#{@dj_set.name} created successfully with #{@dj_set.tracks.count} tracks"
      else
        Rails.logger.info "DJ Set import failed: Invalid data or file error"
        flash.now[:alert] = "Failed to import DJ Set. Please check the file format."
        render :new, status: :unprocessable_entity
      end
    # Mode 2: Create empty set or add selected tracks
    else
      @dj_set = DjSet.new(dj_set_params)

      if @dj_set.save
        # Add tracks if coming from track selection
        add_selected_tracks_to_set if params[:track_ids].present?
        redirect_to @dj_set, notice: "#{@dj_set.name} created successfully"
      else
        render :new, status: :unprocessable_entity
      end
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

  # POST /dj_sets/:id/import_tracks
  def import_tracks
    file = params[:file]

    if file.blank?
      redirect_to @dj_set, alert: "Please select a file to import"
      return
    end

    importer = DjSetImporter.new(@dj_set, file)
    if importer.call
      @dj_set.reload
      redirect_to @dj_set, notice: "Successfully imported tracks. Set now has #{@dj_set.tracks.count} tracks."
    else
      redirect_to @dj_set, alert: "Failed to import tracks. Please check the file format."
    end
  end

  # POST /dj_sets/:id/optimize
  def optimize
    # Store current order in session (for revert)
    session[:pre_optimization_order] = @dj_set.dj_sets_tracks
                                              .order(:order)
                                              .pluck(:track_id)

    options = optimization_params
    @result = @dj_set.optimize_order!(options)

    redirect_to dj_set_path(@dj_set),
                notice: "Set optimized! Score: #{@result[:old_score].round(1)} → " \
                        "#{@result[:new_score].round(1)} (+#{@result[:score_improvement]}%) " \
                        "using #{@result[:method].humanize} in #{@result[:computation_time]}s"
  rescue StandardError => e
    redirect_to dj_set_path(@dj_set), alert: "Optimization failed: #{e.message}"
  end

  # PATCH /dj_sets/:id/revert_optimization
  def revert_optimization
    previous_order = session[:pre_optimization_order]

    if previous_order
      previous_order.each_with_index do |track_id, index|
        dj_set_track = @dj_set.dj_sets_tracks.find_by(track_id: track_id)
        dj_set_track&.update_column(:order, index + 1)
      end

      session.delete(:pre_optimization_order)
      redirect_to dj_set_path(@dj_set), notice: "Reverted to previous order"
    else
      redirect_to dj_set_path(@dj_set), alert: "No previous order found"
    end
  end

  private

  def set_dj_set
    @dj_set = DjSet.find(params[:id])
  end

  def dj_set_params
    params.expect(dj_set: %i[name description file])
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

  def optimization_params
    permitted = params.permit(
      :start_track_id,
      :end_track_id,
      :harmonic_weight,
      :energy_weight
    ).to_h.symbolize_keys

    # Convert track IDs to Track objects
    permitted[:start_with] = Track.find(permitted.delete(:start_track_id)) if permitted[:start_track_id].present?
    permitted[:end_with] = Track.find(permitted.delete(:end_track_id)) if permitted[:end_track_id].present?

    # Convert weights to floats
    if permitted[:harmonic_weight].present?
      permitted[:harmonic_weight] = permitted[:harmonic_weight].to_f
      permitted[:energy_weight] = 1.0 - permitted[:harmonic_weight]
    end

    permitted
  end
end
# rubocop:enable Metrics/ClassLength
