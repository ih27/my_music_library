# frozen_string_literal: true

# Imports DJ Sets from tab-delimited files
# Inherits shared file parsing logic from TrackImporter
# Unlike PlaylistImporter, does not check for duplicates
class DjSetImporter < TrackImporter
  def initialize(dj_set, file)
    super(file)
    @dj_set = dj_set
  end

  # rubocop:disable Metrics/MethodLength
  def call
    begin
      parse_file
    rescue StandardError => e
      Rails.logger.error "File parsing failed: #{e.message}"
      return false
    end

    return false if @tracks_data.empty?

    ActiveRecord::Base.transaction do
      Rails.logger.info(
        "Attempting to import tracks into DJ Set: #{@dj_set.name}"
      )

      # Save DJ Set if it's a new record
      if @dj_set.new_record?
        begin
          @dj_set.save!
          Rails.logger.info "DJ Set saved successfully with id: #{@dj_set.id}"
        rescue ActiveRecord::RecordInvalid => e
          Rails.logger.error "DJ Set validation failed: #{e.record.errors.full_messages.join(', ')}"
          return false
        end
      end

      # Calculate starting order (for appending to existing sets)
      starting_order = @dj_set.dj_sets_tracks.maximum(:order) || 0

      @tracks_data.each_with_index do |track_data, index|
        track = create_or_find_track(track_data)

        # Use order from file, or calculate next sequential order
        order = starting_order + index + 1
        Rails.logger.info(
          "Creating DjSetsTrack: dj_set=#{@dj_set.id}, track=#{track.id}, order=#{order}"
        )

        # Skip if track already exists in set
        existing = DjSetsTrack.find_by(dj_set: @dj_set, track: track)
        if existing
          Rails.logger.warn "Track #{track.id} already exists in set, skipping"
          next
        end

        dj_sets_track = DjSetsTrack.new(dj_set: @dj_set, track: track, order: order)
        Rails.logger.info "DjSetsTrack attributes: #{dj_sets_track.attributes.inspect}"

        unless dj_sets_track.save
          Rails.logger.error "DjSetsTrack validation failed: #{dj_sets_track.errors.full_messages.join(', ')}"
          raise ActiveRecord::RecordInvalid, dj_sets_track
        end
      end

      # Resequence tracks to ensure sequential order (1, 2, 3...)
      resequence_tracks
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "DJ Set import failed: #{e.message}"
    false
  end

  private

  # Resequence all tracks in the set to ensure sequential order (1, 2, 3, ...)
  # This ensures no gaps in track numbers after import
  def resequence_tracks
    @dj_set.dj_sets_tracks.order(:order).each_with_index do |dj_sets_track, index|
      dj_sets_track.update_column(:order, index + 1)
    end
  end
  # rubocop:enable Metrics/MethodLength
end
