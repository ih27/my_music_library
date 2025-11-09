# frozen_string_literal: true

# Service for detailed set analysis with penalties and bonuses
#
# Scoring System v2.0: Analyzes a set and provides:
# - Base harmonic flow score (from CamelotWheelService)
# - Consecutive penalty (for 3+ same-key transitions in a row)
# - Variety bonus (for using diverse transition types)
# - Insights and recommendations
#
class SetAnalysisService
  attr_reader :tracks, :transitions

  def initialize(ordered_tracks)
    @tracks = ordered_tracks
    @transitions = build_transitions
  end

  # Calculate final score with penalties and bonuses applied
  #
  # @return [Float] Final score (0-100)
  def score
    [base_score - consecutive_penalty + variety_bonus, 0].max.round(1)
  end

  # Get detailed analysis breakdown
  #
  # @return [Hash] Detailed analysis with scores and insights
  def detailed_analysis
    {
      base_score: base_score,
      consecutive_penalty: consecutive_penalty,
      variety_bonus: variety_bonus,
      final_score: score,
      insights: generate_insights,
      transition_breakdown: transition_breakdown
    }
  end

  private

  # Base harmonic flow score using CamelotWheelService
  def base_score
    return 100.0 if @transitions.empty?

    CamelotWheelService.harmonic_flow_score(@transitions)
  end

  # Penalize 3+ consecutive perfect matches (boring mixing)
  # Formula: (consecutive_count - 2) * 5 points per run
  # Capped at 30 points maximum penalty
  def consecutive_penalty
    runs = find_consecutive_runs(:perfect)
    penalty = runs.select { |count| count >= 3 }.sum { |count| (count - 2) * 5 }
    [penalty, 30].min
  end

  # Bonus for good mix of transition types (variety encouragement)
  # 3-4 different types: +10 points
  # 2 types: +5 points
  # 1 type or only 1 transition: 0 points
  def variety_bonus
    return 0 if @transitions.count < 2

    types = @transitions.pluck(:quality).uniq

    case types.count
    when 3..4 then 10  # Using 3-4 different transition types
    when 2    then 5   # Using 2 types
    else           0   # All same type
    end
  end

  # Find consecutive runs of a specific quality type
  #
  # @param quality_type [Symbol] Quality to look for (:perfect, :smooth, etc.)
  # @return [Array<Integer>] Array of run lengths
  def find_consecutive_runs(quality_type)
    runs = []
    current_run = 0

    @transitions.each do |t|
      if t[:quality] == quality_type
        current_run += 1
      else
        runs << current_run if current_run.positive?
        current_run = 0
      end
    end
    runs << current_run if current_run.positive?

    runs
  end

  # Generate human-readable insights about the set
  #
  # @return [Array<String>] Array of insight strings
  def generate_insights
    insights = []

    # Check for boring sections (consecutive perfect matches)
    perfect_runs = find_consecutive_runs(:perfect)
    if perfect_runs.any? { |r| r >= 3 }
      max_run = perfect_runs.max
      insights << "⚠️ #{max_run} consecutive same-key transitions detected - consider adding variety"
    end

    # Check for rough transitions
    rough_count = @transitions.count { |t| t[:quality] == :rough }
    insights << "🟡 #{rough_count} rough transition(s) - consider reordering for better flow" if rough_count.positive?

    # Praise good variety
    types_used = @transitions.pluck(:quality).uniq.count
    insights << "✨ Great variety of transition types with smooth flow!" if types_used >= 3 && rough_count.zero?

    # Check for good energy management
    energy_boost_count = @transitions.count { |t| t[:quality] == :energy_boost }
    insights << "⚡ #{energy_boost_count} energy boost(s) detected - good for building peaks" if energy_boost_count.positive?

    # Overall quality assessment
    final = score
    if final >= 90
      insights << "🎵 Excellent harmonic mixing - professional quality!"
    elsif final >= 75
      insights << "👍 Good harmonic flow with room for minor improvements"
    elsif final < 60 && rough_count.positive?
      insights << "💡 Tip: Focus on compatible key transitions to improve flow"
    end

    insights
  end

  # Get breakdown of transition types
  #
  # @return [Hash] Count of each transition quality type
  def transition_breakdown
    return {} if @transitions.empty?

    breakdown = {
      perfect: 0,
      smooth: 0,
      energy_boost: 0,
      rough: 0
    }

    @transitions.each do |t|
      breakdown[t[:quality]] ||= 0
      breakdown[t[:quality]] += 1
    end

    breakdown
  end

  # Build transitions array from ordered tracks
  #
  # @return [Array<Hash>] Array of transition hashes
  def build_transitions
    return [] if @tracks.count < 2

    # Filter out tracks without keys
    tracks_with_keys = @tracks.select { |t| t.key.present? }
    return [] if tracks_with_keys.count < 2

    tracks_with_keys.each_cons(2).map do |from_track, to_track|
      {
        from_track: from_track,
        to_track: to_track,
        from_key: from_track.key.name,
        to_key: to_track.key.name,
        quality: CamelotWheelService.transition_quality(
          from_track.key.name,
          to_track.key.name
        )
      }
    end
  end
end
