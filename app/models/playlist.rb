# frozen_string_literal: true

class Playlist < ApplicationRecord
  has_many :playlists_tracks, dependent: :destroy
  has_many :tracks, through: :playlists_tracks
  has_one_attached :cover_art

  validates :name, presence: true

  after_create :attach_default_cover_art

  def unique_identifier
    tracks.order(:id).pluck(:id).join("-")
  end

  # Analyze harmonic transitions between consecutive tracks
  #
  # @return [Array<Hash>] Array of transition hashes with :from, :to, :quality, :indicator
  def analyze_transitions
    analysis = HarmonicMixingService.analyze_playlist_transitions(self)
    analysis[:transitions]
  end

  # Calculate overall harmonic flow score for this playlist
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
    tracks_in_order = playlists_tracks.includes(track: :key).order(:order).map(&:track)
    SetAnalysisService.new(tracks_in_order).detailed_analysis
  end

  # Get ordered tracks for this playlist
  #
  # @return [Array<Track>] Tracks in playlist order
  def tracks_in_order
    playlists_tracks.includes(:track).order(:order).map(&:track)
  end

  # Convert this playlist to a DJ Set
  # Playlists are read-only historical records, so this creates a new editable DJ Set
  # for optimization experiments without deleting the original playlist.
  #
  # @param name [String, nil] Optional custom name for the DJ Set
  # @return [DjSet] Newly created DJ Set with copied tracks
  def convert_to_dj_set(name: nil)
    dj_set_name = name.presence || "#{self.name} (DJ Set)"

    dj_set = DjSet.create!(
      name: dj_set_name,
      description: "Converted from playlist: #{self.name}"
    )

    # Copy tracks in exact order
    playlists_tracks.order(:order).each do |pt|
      dj_set.dj_sets_tracks.create!(
        track: pt.track,
        order: pt.order
      )
    end

    dj_set
  end

  private

  def attach_default_cover_art
    return if cover_art.attached?

    cover_art.attach(
      io: Rails.root.join("app/assets/images/default_cover_art.jpg").open,
      filename: "default_cover_art.jpg",
      content_type: "image/jpg"
    )
  end
end
