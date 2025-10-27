# frozen_string_literal: true

# Service for handling Camelot Wheel harmonic mixing logic
#
# The Camelot Wheel maps musical keys to a 12-position wheel with two modes:
# - A (Minor keys): 1A-12A
# - B (Major keys): 1B-12B
#
# Compatible transitions:
# - Perfect: Same key (8A → 8A)
# - Smooth: ±1 position (8A → 7A or 9A) or relative major/minor (8A ↔ 8B)
# - Energy Boost: +7 positions (8A → 3A)
# - Rough: All other transitions

class CamelotWheelService
  POSITIONS = (1..12).to_a
  MODES = %w[A B].freeze

  # Visual indicators for transition quality
  INDICATORS = {
    perfect: "🟢",
    smooth: "🔵",
    energy_boost: "⚡",
    rough: "🟡"
  }.freeze

  # Parse Camelot notation (e.g., "8A" → {position: 8, mode: 'A'})
  #
  # @param key_name [String] Camelot key notation (e.g., "8A", "12B")
  # @return [Hash] Parsed key {position: Integer, mode: String}
  def self.parse_key(key_name)
    return nil unless key_name

    match = key_name.match(/^(\d+)([AB])$/)
    return nil unless match

    position = match[1].to_i
    mode = match[2]

    return nil unless POSITIONS.include?(position)

    { position: position, mode: mode }
  end

  # Calculate all compatible keys for a given key
  #
  # @param key_name [String] Camelot key notation (e.g., "8A")
  # @param level [Symbol] Compatibility level (:same, :smooth, :energy_boost, :all)
  # @return [Array<String>] Array of compatible key names
  def self.compatible_keys(key_name, level: :all)
    parsed = parse_key(key_name)
    return [] unless parsed

    position = parsed[:position]
    mode = parsed[:mode]
    compatible = []

    case level
    when :same
      compatible << key_name
    when :smooth
      # ±1 position
      compatible << format_key(increment_position(position, -1), mode)
      compatible << format_key(increment_position(position, 1), mode)
      # Relative major/minor
      compatible << format_key(position, opposite_mode(mode))
    when :energy_boost
      # +7 positions
      compatible << format_key(increment_position(position, 7), mode)
    when :all
      # Same key
      compatible << key_name
      # ±1 position
      compatible << format_key(increment_position(position, -1), mode)
      compatible << format_key(increment_position(position, 1), mode)
      # Relative major/minor
      compatible << format_key(position, opposite_mode(mode))
      # Energy boost (+7)
      compatible << format_key(increment_position(position, 7), mode)
    end

    compatible.uniq
  end

  # Determine the quality of transition between two keys
  #
  # @param from_key [String] Starting key (e.g., "8A")
  # @param to_key [String] Destination key (e.g., "8B")
  # @return [Symbol] Quality: :perfect, :smooth, :energy_boost, or :rough
  def self.transition_quality(from_key, to_key)
    return :rough unless from_key && to_key

    from = parse_key(from_key)
    to = parse_key(to_key)
    return :rough unless from && to

    # Perfect match (same key)
    return :perfect if from_key == to_key

    # Smooth transitions and energy boost (same mode only)
    if from[:mode] == to[:mode]
      # Calculate forward distance (positive direction on wheel)
      forward_diff = (to[:position] - from[:position]) % 12

      # Energy boost (+7 positions forward)
      return :energy_boost if forward_diff == 7

      # ±1 position
      diff = position_difference(from[:position], to[:position])
      return :smooth if diff == 1
    end

    # Relative major/minor (same position, different mode)
    return :smooth if from[:position] == to[:position] && from[:mode] != to[:mode]

    # Everything else is rough
    :rough
  end

  # Calculate harmonic flow score for a playlist
  #
  # @param transitions [Array<Hash>] Array of transition hashes with :quality key
  # @return [Float] Score from 0-100
  def self.harmonic_flow_score(transitions)
    return 100.0 if transitions.empty?

    weights = {
      perfect: 3,
      smooth: 2,
      energy_boost: 2,
      rough: 0
    }

    total_score = transitions.sum { |t| weights[t[:quality]] || 0 }
    max_score = transitions.size * weights[:perfect]

    (total_score.to_f / max_score * 100).round(1)
  end

  # Get visual indicator for transition quality
  #
  # @param quality [Symbol] Transition quality
  # @return [String] Emoji indicator
  def self.indicator(quality)
    INDICATORS[quality] || INDICATORS[:rough]
  end

  # Increment position with wrapping (1-12)
  def self.increment_position(position, delta)
    ((position - 1 + delta) % 12) + 1
  end

  # Calculate circular difference between positions
  def self.position_difference(from, to)
    diff = (to - from) % 12
    [diff, 12 - diff].min
  end

  # Get opposite mode (A ↔ B)
  def self.opposite_mode(mode)
    mode == "A" ? "B" : "A"
  end

  # Format key as Camelot notation
  def self.format_key(position, mode)
    "#{position}#{mode}"
  end
end
