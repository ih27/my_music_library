# frozen_string_literal: true

# Base class for importing tracks from tab-delimited files
# Shared logic for PlaylistImporter and DjSetImporter
class TrackImporter
  REQUIRED_HEADERS = ["#", "Track Title", "Artist", "BPM", "Date Added"].freeze
  OPTIONAL_HEADERS = %w[Key Time Album].freeze

  attr_reader :tracks_data

  def initialize(file)
    @file = file
    @tracks_data = []
    @headers_map = {}
  end

  protected

  # Parse the uploaded file and populate tracks_data array
  def parse_file
    return if @file.blank?

    file_content = @file.read
    detected_encoding = detect_encoding(file_content)
    Rails.logger.debug { "Detected encoding: #{detected_encoding}" }
    sanitized_content = sanitize_input(file_content, detected_encoding)
    lines = sanitized_content.split("\n")

    # Parse headers
    header_line = lines.shift
    Rails.logger.debug { "Headers: #{header_line.inspect}" }
    parse_headers(header_line)

    lines.each do |line|
      data = line.split("\t")
      next if data.size < @headers_map.size # Skip lines that don't have enough data

      begin
        track_data = process_line(data)
        @tracks_data << track_data if track_data
      rescue StandardError => e
        Rails.logger.error "Failed to process line: #{line}. Error: #{e.message}"
      end
    end
  end

  # Parse header line and validate required headers
  def parse_headers(header_line)
    headers = header_line.split("\t").map { |h| h.strip.gsub(/\A[\u{FEFF}\u{200B}]+/, "") }

    REQUIRED_HEADERS.each do |required_header|
      raise "Missing required header: #{required_header}" unless headers.any? { |h| h == required_header }
    end

    (REQUIRED_HEADERS + OPTIONAL_HEADERS).each do |header|
      index = headers.index(header)
      @headers_map[header] = index if index
    end
  end

  # Process a single line from the file and return track data hash
  def process_line(data)
    track_artists = data[@headers_map["Artist"]].split(", ")
    key_name = data[@headers_map["Key"]] if @headers_map["Key"]
    key = Key.find_or_create_by!(name: key_name) if key_name.present?

    track_attributes = {
      name: data[@headers_map["Track Title"]],
      bpm: data[@headers_map["BPM"]].to_d,
      date_added: Date.parse(data[@headers_map["Date Added"]])
    }
    track_attributes[:key] = key if key
    track_attributes[:time] = convert_time_to_seconds(data[@headers_map["Time"]]) if @headers_map["Time"]
    track_attributes[:album] = data[@headers_map["Album"]].presence if @headers_map["Album"]

    order = data[@headers_map["#"]].to_i
    { track_attributes: track_attributes, artists: track_artists, order: order }
  end

  # Detect character encoding using rchardet
  def detect_encoding(content)
    CharDet.detect(content)["encoding"]
  end

  # Sanitize input by converting to UTF-8 and removing BOM
  def sanitize_input(input, encoding)
    content = input.force_encoding(encoding).encode("UTF-8", invalid: :replace, undef: :replace, replace: "")
    content.gsub(/\A\xEF\xBB\xBF/, "") # Remove BOM if present
  end

  # Convert MM:SS time string to seconds
  def convert_time_to_seconds(time_str)
    return nil unless time_str

    mins, secs = time_str.split(":").map(&:to_i)
    (mins * 60) + secs
  end

  # Create or find a track with its associations
  # Returns the Track object
  def create_or_find_track(track_data)
    track = Track.find_or_create_by!(track_data[:track_attributes])
    track_data[:artists].each do |artist_name|
      artist = Artist.find_or_create_by!(name: artist_name)
      track.artists << artist unless track.artists.include?(artist)
    end
    track
  end
end
