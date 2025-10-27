# frozen_string_literal: true

class Track < ApplicationRecord
  belongs_to :key, optional: true
  has_many :playlists_tracks, dependent: :destroy
  has_many :playlists, through: :playlists_tracks
  has_and_belongs_to_many :artists
  has_one_attached :audio_file

  validates :name, :bpm, :date_added, presence: true
  validates :key, presence: true, unless: -> { key_id.nil? }
  validates :audio_file, presence: true, blob: { content_type: :audio }, if: -> { audio_file.attached? }

  def self.search(query)
    query = "%#{query.downcase}%"
    joins(:artists, :key, :playlists).where(
      "LOWER(tracks.name) LIKE ? OR LOWER(tracks.bpm) LIKE ? OR LOWER(artists.name) LIKE ? OR LOWER(keys.name) LIKE ? OR LOWER(playlists.name) LIKE ?",
      query, query, query, query, query
    ).distinct
  end

  # Find all compatible tracks grouped by compatibility type
  #
  # @param bpm_range [Integer, nil] Optional BPM range tolerance (±)
  # @return [Hash] Hash with keys :perfect, :smooth, :energy_boost
  def find_compatible(bpm_range: nil)
    service = HarmonicMixingService.new(self, bpm_range: bpm_range)
    service.find_compatible_tracks
  end

  # Check if this track is compatible with another track
  #
  # @param other_track [Track] Track to check compatibility with
  # @param bpm_range [Integer, nil] Optional BPM range tolerance (±)
  # @return [Boolean]
  def compatible_with?(other_track, bpm_range: nil)
    return false unless key && other_track&.key

    # Check key compatibility
    quality = CamelotWheelService.transition_quality(key.name, other_track.key.name)
    key_compatible = quality != :rough

    return key_compatible unless bpm_range

    # Check BPM compatibility if range specified
    bpm_diff = (bpm - other_track.bpm).abs
    key_compatible && bpm_diff <= bpm_range
  end
end
