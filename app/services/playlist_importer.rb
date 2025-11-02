# frozen_string_literal: true

# Imports playlists from tab-delimited files (e.g., Rekordbox exports)
# Inherits shared file parsing logic from TrackImporter
class PlaylistImporter < TrackImporter
  def initialize(playlist, file)
    super(file)
    @playlist = playlist
    @track_ids = []
  end

  def call
    parse_file
    return false if @tracks_data.empty?

    # Collect track IDs to check for duplicates
    collect_track_ids
    return false if duplicate_playlist?

    ActiveRecord::Base.transaction do
      Rails.logger.info(
        "Attempting to save playlist with track_ids: #{@track_ids.inspect}"
      )

      begin
        @playlist.save!
        Rails.logger.info "Playlist saved successfully with id: #{@playlist.id}"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Playlist validation failed: #{e.record.errors.full_messages.join(', ')}"
        return false
      end

      @tracks_data.each_with_index do |track_data, index|
        track = create_or_find_track(track_data)

        order = track_data[:order] || (index + 1)
        Rails.logger.info(
          "Creating PlaylistsTrack: playlist=#{@playlist.id}, track=#{track.id}, order=#{order}"
        )

        playlists_track = PlaylistsTrack.new(playlist: @playlist, track: track, order: order)
        Rails.logger.info "PlaylistsTrack attributes: #{playlists_track.attributes.inspect}"

        unless playlists_track.save
          Rails.logger.error "PlaylistsTrack validation failed: #{playlists_track.errors.full_messages.join(', ')}"
          raise ActiveRecord::RecordInvalid, playlists_track
        end
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Playlist creation failed: #{e.message}"
    false
  end

  private

  # Collect track IDs by finding or initializing tracks from track_data
  # This is used for duplicate detection before saving
  def collect_track_ids
    @tracks_data.each do |track_data|
      track = Track.find_or_initialize_by(track_data[:track_attributes])
      @track_ids << track.id if track.persisted?
    end
  end

  def duplicate_playlist?
    new_playlist_identifier = @track_ids.sort.join("-")
    Rails.logger.info "New playlist identifier: #{new_playlist_identifier}"

    duplicates = Playlist.all.select { |playlist| playlist.unique_identifier == new_playlist_identifier }
    duplicates.each do |duplicate|
      Rails.logger.info "Found duplicate playlist with ID: #{duplicate.id} and name: #{duplicate.name}"
    end

    duplicates.any?
  end
end
