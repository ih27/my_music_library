class PlaylistImporter
  def initialize(playlist, file)
    @playlist = playlist
    @file = file
    @track_ids = []
    @tracks_data = []
  end

  def call
    parse_file if @file.present?
    return false if @track_ids.empty?
    return false if duplicate_playlist?

    ActiveRecord::Base.transaction do
      Rails.logger.info "Attempting to save playlist with track_ids: #{@track_ids.inspect}"

      begin
        @playlist.save!
        Rails.logger.info "Playlist saved successfully with id: #{@playlist.id}"
      rescue ActiveRecord::RecordInvalid => e
        Rails.logger.error "Playlist validation failed: #{e.record.errors.full_messages.join(', ')}"
        return false
      end

      @tracks_data.each_with_index do |track_data, index|
        track = Track.find_or_create_by!(track_data[:track_attributes])
        track_data[:artists].each do |artist_name|
          artist = Artist.find_or_create_by!(name: artist_name)
          track.artists << artist unless track.artists.include?(artist)
        end

        # Ensure order is set and log detailed information before creating PlaylistsTrack
        order = track_data[:order] || index + 1
        Rails.logger.info "Creating PlaylistsTrack with playlist_id: #{@playlist.id}, track_id: #{track.id}, order: #{order}"
        
        # Create PlaylistsTrack and handle potential validation errors
        playlists_track = PlaylistsTrack.new(playlist: @playlist, track: track, order: order)
        Rails.logger.info "PlaylistsTrack attributes: #{playlists_track.attributes.inspect}"
        
        unless playlists_track.save
          Rails.logger.error "PlaylistsTrack validation failed: #{playlists_track.errors.full_messages.join(', ')}"
          raise ActiveRecord::RecordInvalid.new(playlists_track)
        end
      end
    end
    true
  rescue ActiveRecord::RecordInvalid => e
    Rails.logger.error "Playlist creation failed: #{e.message}"
    false
  end


  private

  def parse_file
    file_content = @file.read
    detected_encoding = detect_encoding(file_content)
    sanitized_content = sanitize_input(file_content, detected_encoding)
    lines = sanitized_content.split("\n").drop(1) # Skip the header line

    lines.each do |line|
      data = line.split("\t")
      next if data.size < 9 # Skip lines that don't have enough data

      begin
        track_data = process_line(data)
        track = Track.find_or_initialize_by(track_data[:track_attributes])
        @track_ids << track.id if track_data
        @tracks_data << track_data if track_data
      rescue => e
        Rails.logger.error "Failed to process line: #{line}. Error: #{e.message}"
      end
    end
  end

  def process_line(data)
    track_artists = data[2].split(', ')
    track_attributes = {
      name: data[1],
      key: data[4],
      bpm: data[5].to_d,
      time: convert_time_to_seconds(data[6]),
      album: data[7].presence, # Handle potential empty album
      date_added: Date.parse(data[8])
    }
    order = data[0].to_i
    { track_attributes: track_attributes, artists: track_artists, order: order }
  end

  def detect_encoding(content)
    detection = CharlockHolmes::EncodingDetector.detect(content)
    detection[:encoding]
  end

  def sanitize_input(input, encoding)
    input.force_encoding(encoding).encode('UTF-8', invalid: :replace, undef: :replace, replace: '')
  end

  def convert_time_to_seconds(time_str)
    mins, secs = time_str.split(':').map(&:to_i)
    mins * 60 + secs
  end

  def duplicate_playlist?
    new_playlist_identifier = @track_ids.sort.join('-')
    Rails.logger.info "New playlist identifier: #{new_playlist_identifier}"

    duplicates = Playlist.all.select { |playlist| playlist.unique_identifier == new_playlist_identifier }
    duplicates.each do |duplicate|
      Rails.logger.info "Found duplicate playlist with ID: #{duplicate.id} and name: #{duplicate.name}"
    end

    duplicates.any?
  end
end
