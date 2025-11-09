# frozen_string_literal: true

class DjSet < ApplicationRecord
  has_many :dj_sets_tracks, dependent: :destroy
  has_many :tracks, through: :dj_sets_tracks

  validates :name, presence: true, uniqueness: { case_sensitive: false }, length: { maximum: 100 }
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Returns total duration of all tracks in seconds
  #
  # @return [Integer] Total duration in seconds
  def total_duration
    tracks.sum(:time)
  end

  # Returns formatted duration string (HH:MM:SS or MM:SS)
  #
  # @return [String] Formatted duration
  def total_duration_formatted
    seconds = total_duration
    return "0:00" if seconds.zero?

    Time.at(seconds).utc.strftime(seconds >= 3600 ? "%H:%M:%S" : "%M:%S")
  end

  # Returns average BPM of all tracks, rounded to 1 decimal
  #
  # @return [Float] Average BPM
  def average_bpm
    return 0.0 if tracks.empty?

    (tracks.average(:bpm) || 0).round(1)
  end

  # Returns tracks in order specified by dj_sets_tracks.order column
  #
  # @return [ActiveRecord::Relation<Track>] Ordered tracks
  def ordered_tracks
    tracks.order('dj_sets_tracks."order"')
  end

  # Analyze harmonic transitions between consecutive tracks
  #
  # @return [Array<Hash>] Array of transition hashes with :from, :to, :quality, :indicator
  def analyze_transitions
    analysis = HarmonicMixingService.analyze_playlist_transitions(self)
    analysis[:transitions]
  end

  # Calculate overall harmonic flow score for this set
  #
  # @return [Float] Score from 0-100
  def harmonic_flow_score
    analysis = HarmonicMixingService.analyze_playlist_transitions(self)
    analysis[:score]
  end

  # Get full harmonic analysis including transitions and statistics
  #
  # @return [Hash] Complete analysis with :transitions, :score, :total_transitions, :quality_counts
  def harmonic_analysis
    HarmonicMixingService.analyze_playlist_transitions(self)
  end

  # Get detailed harmonic analysis with penalties, bonuses, and insights
  # Uses SetAnalysisService for Scoring System v2.0
  #
  # @return [Hash] Detailed analysis with :base_score, :consecutive_penalty, :variety_bonus, :final_score, :insights
  def detailed_harmonic_analysis
    tracks_in_order = dj_sets_tracks.includes(track: :key).order(:order).map(&:track)
    SetAnalysisService.new(tracks_in_order).detailed_analysis
  end

  # Get ordered tracks for this set
  #
  # @return [Array<Track>] Tracks in set order
  def tracks_in_order
    dj_sets_tracks.includes(:track).order(:order).map(&:track)
  end

  # Optimize track order using PlaylistOptimizerService
  #
  # @param options [Hash] Options for optimization (harmonic_weight, energy_weight, start_with, end_with, etc.)
  # @return [Hash] Optimization result with :order, :score, :method, :computation_time, etc.
  def optimize_order!(options = {})
    optimizer = PlaylistOptimizerService.new(self, options)
    result = optimizer.optimize!
    optimizer.apply_optimization!
    result
  end

  # Create a duplicate of this set with a new name
  #
  # @param new_name [String] Name for the duplicated set
  # @return [DjSet] The newly created set
  def duplicate(new_name: "#{name} (Copy)")
    new_set = dup
    new_set.name = new_name
    new_set.save!

    dj_sets_tracks.each do |st|
      new_set.dj_sets_tracks.create!(track: st.track, order: st.order)
    end

    new_set
  end

  # Export set to tab-delimited file format compatible with PlaylistImporter
  #
  # @return [String] Tab-delimited file content
  def export_to_file
    headers = ["#", "Track Title", "Artist", "BPM", "Key", "Time", "Album", "Date Added"]
    lines = [headers.join("\t")]

    ordered_tracks.includes(:artists, :key).each_with_index do |track, index|
      lines << [
        index + 1,
        track.name,
        track.artists.pluck(:name).join(", "),
        track.bpm,
        track.key&.name || "",
        format_time_for_export(track.time),
        track.album || "",
        track.date_added&.strftime("%Y-%m-%d") || ""
      ].join("\t")
    end

    lines.join("\n")
  end

  # Convert this set to a playlist with cover art
  #
  # @param name [String, nil] Name for the new playlist (defaults to set name)
  # @param cover_art [ActiveStorage::Attached, nil] Optional cover art attachment
  # @return [Playlist] The newly created playlist
  def convert_to_playlist(name: nil, cover_art: nil)
    playlist = Playlist.create!(name: name || self.name)

    # Attach cover art if provided
    playlist.cover_art.attach(cover_art) if cover_art

    # Copy tracks in order
    ordered_tracks.each_with_index do |track, index|
      playlist.playlists_tracks.create!(track: track, order: index + 1)
    end

    playlist
  end

  private

  # Format time in seconds to MM:SS format for export
  #
  # @param seconds [Integer] Time in seconds
  # @return [String] Formatted time string
  def format_time_for_export(seconds)
    return "0:00" if seconds.nil? || seconds.zero?

    minutes = seconds / 60
    secs = seconds % 60
    format("%d:%02d", minutes, secs)
  end
end
