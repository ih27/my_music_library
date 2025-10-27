# frozen_string_literal: true

# Service for finding compatible tracks and analyzing harmonic mixing
#
# This service uses CamelotWheelService to:
# - Find tracks compatible with a given track
# - Apply BPM range filtering
# - Analyze playlist transitions

class HarmonicMixingService
  attr_reader :track, :bpm_range

  def initialize(track, bpm_range: nil)
    @track = track
    @bpm_range = bpm_range
  end

  # Find all compatible tracks grouped by compatibility type
  #
  # @return [Hash] Hash with keys :perfect, :smooth, :energy_boost
  #   Each value is an array of Track objects
  def find_compatible_tracks
    return { perfect: [], smooth: [], energy_boost: [] } unless track.key

    key_name = track.key.name

    # Get compatible key names for each level
    same_keys = CamelotWheelService.compatible_keys(key_name, level: :same)
    smooth_keys = CamelotWheelService.compatible_keys(key_name, level: :smooth)
    energy_keys = CamelotWheelService.compatible_keys(key_name, level: :energy_boost)

    # Find Key records
    same_key_records = Key.where(name: same_keys)
    smooth_key_records = Key.where(name: smooth_keys)
    energy_key_records = Key.where(name: energy_keys)

    # Build base query (exclude the current track)
    base_query = Track.where.not(id: track.id)

    # Apply BPM filtering if specified
    if bpm_range.present? && bpm_range.positive?
      bpm_min = track.bpm - bpm_range
      bpm_max = track.bpm + bpm_range
      base_query = base_query.where(bpm: bpm_min..bpm_max)
    end

    {
      perfect: base_query.where(key: same_key_records).order(:name),
      smooth: base_query.where(key: smooth_key_records).order(:name),
      energy_boost: base_query.where(key: energy_key_records).order(:name)
    }
  end

  # Analyze transitions in a playlist
  #
  # @param playlist [Playlist] The playlist to analyze
  # @return [Hash] Hash with :transitions array and :score
  def self.analyze_playlist_transitions(playlist)
    tracks = playlist.tracks.order('playlists_tracks."order"')
    transitions = []

    tracks.each_cons(2) do |from_track, to_track|
      next unless from_track.key && to_track.key

      quality = CamelotWheelService.transition_quality(
        from_track.key.name,
        to_track.key.name
      )

      transitions << {
        from: from_track,
        to: to_track,
        quality: quality,
        indicator: CamelotWheelService.indicator(quality)
      }
    end

    score = CamelotWheelService.harmonic_flow_score(transitions)

    {
      transitions: transitions,
      score: score,
      total_transitions: transitions.size,
      quality_counts: transitions.group_by { |t| t[:quality] }
                                 .transform_values(&:count)
    }
  end
end
