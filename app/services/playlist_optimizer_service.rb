# frozen_string_literal: true

# Service for optimizing track order in playlists and DJ sets
#
# Uses multiple algorithms based on track count:
# - 2-10 tracks: Brute force (guaranteed optimal)
# - 11-15 tracks: Genetic algorithm (fallback until branch & bound implemented)
# - 16-25 tracks: Genetic algorithm (85-95% optimal)
# - 26+ tracks: Greedy with lookahead (70-85% optimal)
#
# Balances harmonic flow (via SetAnalysisService) with energy arc progression.
#
# This class is intentionally large (>260 lines) as it implements multiple
# optimization algorithms (brute force, genetic, greedy) with shared scoring logic.
# Splitting it would harm cohesion and make the algorithm selection logic harder to follow.
#
# rubocop:disable Metrics/ClassLength
class PlaylistOptimizerService
  # Limits
  MAX_TRACKS_FOR_OPTIMIZATION = 50
  MIN_TRACKS_FOR_OPTIMIZATION = 2

  # BPM range for electronic music
  MIN_BPM = 80
  MAX_BPM = 160

  attr_reader :set_or_playlist, :options, :result

  def initialize(set_or_playlist, options = {})
    @set_or_playlist = set_or_playlist
    @options = default_options.merge(options.symbolize_keys)
    @result = nil
  end

  # Run optimization and return results
  #
  # @return [Hash] Result with :order, :score, :method, :computation_time, etc.
  def optimize!
    validate!

    tracks = set_or_playlist.tracks_in_order

    # Preload keys to avoid N+1 queries during optimization
    ActiveRecord::Associations::Preloader.new(records: tracks, associations: :key).call

    # Store original order for potential revert
    @result = { old_order: tracks.map(&:id) }

    start_time = Time.current

    optimization_result = optimize_order(tracks, options)
    @result.merge!(optimization_result)
    @result[:computation_time] = (Time.current - start_time).round(2)
    @result[:old_score] = current_score(tracks)
    @result[:new_score] = @result[:score]
    @result[:score_improvement] = score_improvement_percentage

    @result
  end

  # Apply optimization result to the set or playlist
  # This is a command method that modifies state (not a predicate query).
  # Returns boolean for success indication only.
  #
  # @return [Boolean] Success
  # rubocop:disable Naming/PredicateMethod
  def apply_optimization!
    return false unless result

    result[:order].each_with_index do |track, index|
      track_record = find_track_record(track)
      track_record&.update_column(:order, index + 1)
    end

    set_or_playlist.touch
    true
  end
  # rubocop:enable Naming/PredicateMethod

  private

  # Find the track record (PlaylistsTrack or DjSetsTrack) for a given track
  def find_track_record(track)
    if set_or_playlist.is_a?(Playlist)
      set_or_playlist.playlists_tracks.find_by(track: track)
    else
      set_or_playlist.dj_sets_tracks.find_by(track: track)
    end
  end

  def default_options
    {
      harmonic_weight: 0.7,
      energy_weight: 0.3,
      start_with: nil,
      end_with: nil,
      generations: 1000,      # For genetic algorithm
      population_size: 100,   # For genetic algorithm
      mutation_rate: 0.1,     # For genetic algorithm
      lookahead: 3            # For greedy algorithm
    }
  end

  def validate!
    track_count = set_or_playlist.tracks.count

    raise ArgumentError, "Must have at least #{MIN_TRACKS_FOR_OPTIMIZATION} tracks" if track_count < MIN_TRACKS_FOR_OPTIMIZATION

    return unless track_count > MAX_TRACKS_FOR_OPTIMIZATION

    raise ArgumentError, "Too large (max #{MAX_TRACKS_FOR_OPTIMIZATION} tracks)"
  end

  # Select and run appropriate algorithm based on track count
  def optimize_order(tracks, opts)
    case tracks.count
    when 0..1
      { order: tracks, score: 100, method: "none" }
    when 2..10
      brute_force_optimal(tracks, opts)
    when 11..25
      # Use genetic algorithm for 11-25 tracks
      # (11-15 will use branch & bound once implemented)
      genetic_algorithm(tracks, opts)
    else
      greedy_with_lookahead(tracks, opts)
    end
  end

  # ===============================
  # ENERGY ARC SCORING
  # ===============================

  # Estimate track energy from BPM and key mode
  #
  # @param track [Track] Track to estimate energy for
  # @return [Float] Energy score 0-100
  def estimate_track_energy(track)
    return 50 if track.bpm.nil? # Default mid-energy if no BPM

    # Base energy from BPM (80% of score)
    bpm_energy = ((track.bpm - MIN_BPM) / (MAX_BPM - MIN_BPM).to_f * 80).clamp(0, 80)

    # Major keys (B) get brightness bonus (20% of score)
    key_mode_bonus = track.key&.name&.end_with?("B") ? 20 : 0

    # Combine (max 100)
    (bpm_energy + key_mode_bonus).clamp(0, 100)
  end

  # Generate ideal energy curve for a given track count
  #
  # @param track_count [Integer] Number of tracks in playlist
  # @return [Array<Float>] Ideal energy values for each position
  def ideal_energy_curve(track_count)
    (0...track_count).map do |i|
      position = i.to_f / track_count # 0.0 to 1.0

      case position
      when 0.0..0.1 # Opening (0-10%): Ease in at mid-energy
        40 + (position * 100) # 40 → 50
      when 0.1..0.6 # Build (10-60%): Steady climb
        50 + ((position - 0.1) * 100) # 50 → 100
      when 0.6..0.7    # Peak (60-70%): Maximum energy
        100
      when 0.7..0.9    # Drop (70-90%): Cool down
        100 - ((position - 0.7) * 250) # 100 → 50
      else # Closing (90-100%): Wind down
        50 - ((position - 0.9) * 400) # 50 → 10
      end.clamp(0, 100)
    end
  end

  # Calculate how well energy progression matches ideal curve
  #
  # @param ordered_tracks [Array<Track>] Tracks in order
  # @return [Float] Score 0-100
  def energy_arc_score(ordered_tracks)
    return 100 if ordered_tracks.count < 3 # Too short to judge

    # Cache energy values per track to avoid recalculation
    @energy_cache ||= {}
    actual_energies = ordered_tracks.map do |t|
      @energy_cache[t.id] ||= estimate_track_energy(t)
    end

    # Cache ideal curve per track count
    @ideal_curve_cache ||= {}
    ideal_energies = @ideal_curve_cache[ordered_tracks.count] ||= ideal_energy_curve(ordered_tracks.count)

    # Calculate Mean Squared Error (lower = better match)
    mse = 0
    actual_energies.each_with_index do |actual, i|
      diff = actual - ideal_energies[i]
      mse += diff * diff
    end
    mse /= actual_energies.count.to_f

    # Convert MSE to 0-100 score (inverse relationship)
    # Max possible MSE = 10,000 (100 points difference squared)
    max_mse = 10_000
    similarity = 1 - (mse / max_mse)

    (similarity * 100).clamp(0, 100)
  end

  # Score an arrangement combining harmonic flow and energy arc
  #
  # @param ordered_tracks [Array<Track>] Tracks in order
  # @param opts [Hash] Options with :harmonic_weight and :energy_weight
  # @return [Float] Combined score 0-100
  def score_arrangement(ordered_tracks, opts = {})
    harmonic_weight = opts[:harmonic_weight] || 0.7
    energy_weight = opts[:energy_weight] || 0.3

    # Score 1: Harmonic transitions (fast path for optimization)
    harmonic_score = fast_harmonic_score(ordered_tracks)

    # Score 2: How well does energy follow ideal curve?
    energy_score = energy_arc_score(ordered_tracks)

    # Weighted combination
    (harmonic_score * harmonic_weight) + (energy_score * energy_weight)
  end

  # Fast harmonic scoring without full SetAnalysisService overhead
  # Used during optimization loops where we score millions of permutations
  #
  # @param ordered_tracks [Array<Track>] Tracks in order
  # @return [Float] Harmonic score 0-100
  def fast_harmonic_score(ordered_tracks)
    return 100.0 if ordered_tracks.count < 2

    # Pre-cache key names to avoid repeated AR queries
    @key_cache ||= {}
    tracks_with_keys = ordered_tracks.select do |t|
      t.key_id.present?
    end

    return 0.0 if tracks_with_keys.count < 2

    # Build transitions and calculate score directly
    total_score = 0
    transition_count = 0

    tracks_with_keys.each_cons(2) do |from_track, to_track|
      from_key = @key_cache[from_track.key_id] ||= from_track.key.name
      to_key = @key_cache[to_track.key_id] ||= to_track.key.name

      total_score += CamelotWheelService.transition_score(from_key, to_key)
      transition_count += 1
    end

    return 0.0 if transition_count.zero?

    # Return average score (0-100)
    (total_score / transition_count.to_f).clamp(0, 100)
  end

  # Score a single transition between tracks
  #
  # @param from_track [Track] Starting track
  # @param to_track [Track] Destination track
  # @param opts [Hash] Options
  # @return [Float] Transition score
  def score_transition(from_track, to_track, _opts = {})
    return 0 if from_track.nil? || to_track.nil?
    return 0 if from_track.key.nil? || to_track.key.nil?

    CamelotWheelService.transition_score(from_track.key.name, to_track.key.name)
  end

  # Get current score of playlist
  def current_score(tracks = nil)
    tracks ||= playlist.tracks_in_order
    score_arrangement(tracks, options)
  end

  def score_improvement_percentage
    return 0 if result[:old_score].zero?

    ((result[:new_score] - result[:old_score]) / result[:old_score] * 100).round(1)
  end

  # ===============================
  # CONSTRAINT HELPERS
  # ===============================

  # Apply start/end constraints to track list
  def apply_constraints(tracks, start_track, end_track)
    tracks - [start_track, end_track].compact
  end

  # Build full order with constraints
  def build_full_order(candidates, start_track, end_track)
    order = []
    order << start_track if start_track
    order += candidates
    order << end_track if end_track
    order
  end

  # Remove locked tracks for mutation/crossover
  def remove_locked_tracks(order, start_track, end_track)
    order - [start_track, end_track].compact
  end

  # ===============================
  # ALGORITHM 1: BRUTE FORCE (2-10 tracks)
  # ===============================

  def brute_force_optimal(tracks, opts)
    start_track = opts[:start_with]
    end_track = opts[:end_with]

    candidates = apply_constraints(tracks, start_track, end_track)

    best_order = nil
    best_score = -Float::INFINITY

    # Reuse array to avoid allocations
    full_order = []
    full_order << start_track if start_track

    candidates.permutation.each do |order|
      # Reuse full_order array - just replace middle section
      if start_track
        full_order[1, order.size] = order
        full_order[order.size + 1] = end_track if end_track
      else
        full_order[0, order.size] = order
        full_order[order.size] = end_track if end_track
      end

      score = score_arrangement(full_order, opts)

      if score > best_score
        best_score = score
        best_order = full_order.dup # Only dup when we find a better solution
      end
    end

    { order: best_order, score: best_score, method: "brute_force" }
  end

  # ===============================
  # ALGORITHM 2: GENETIC ALGORITHM (16-25 tracks)
  # ===============================

  def genetic_algorithm(tracks, opts)
    generations = opts[:generations] || 1000
    population_size = opts[:population_size] || 100
    mutation_rate = opts[:mutation_rate] || 0.1

    start_track = opts[:start_with]
    end_track = opts[:end_with]

    # Initialize population with random orderings
    population = initialize_population(
      tracks,
      population_size,
      start_track,
      end_track
    )

    best_ever = { order: nil, score: -Float::INFINITY }

    generations.times do
      # Score all individuals
      scored_population = population.map do |order|
        { order: order, score: score_arrangement(order, opts) }
      end

      # Track best
      generation_best = scored_population.max_by { |i| i[:score] }
      best_ever = generation_best if generation_best[:score] > best_ever[:score]

      # Selection: Keep top 20% using partial_sort for efficiency
      elite_size = (population_size * 0.2).to_i
      elite = scored_population.max(elite_size) { |a, b| a[:score] <=> b[:score] }

      # Reproduction: Generate new population (reuse elite orders)
      new_population = elite.map { |i| i[:order] }

      while new_population.size < population_size
        parent1 = tournament_select(elite)
        parent2 = tournament_select(elite)
        child = crossover(parent1, parent2, start_track, end_track)
        child = mutate(child, mutation_rate, start_track, end_track)
        new_population << child
      end

      population = new_population
    end

    {
      order: best_ever[:order],
      score: best_ever[:score],
      method: "genetic_algorithm",
      generations: generations
    }
  end

  def initialize_population(tracks, size, start_track, end_track)
    candidates = apply_constraints(tracks, start_track, end_track)

    Array.new(size) do
      shuffled = candidates.shuffle
      build_full_order(shuffled, start_track, end_track)
    end
  end

  # Ordered Crossover (OX): preserve relative order from both parents
  def crossover(parent1, parent2, start_track, end_track)
    # Remove locked tracks for crossover operation
    p1_genes = remove_locked_tracks(parent1, start_track, end_track)
    p2_genes = remove_locked_tracks(parent2, start_track, end_track)

    return build_full_order(p1_genes, start_track, end_track) if p1_genes.size < 2

    # Select random crossover segment
    size = p1_genes.size
    start_idx = rand(0...size)
    end_idx = rand(start_idx...size)

    # Copy segment from parent1
    child = Array.new(size)
    (start_idx..end_idx).each { |i| child[i] = p1_genes[i] }

    # Use Set for O(1) lookup instead of O(n) array.include?
    used = Set.new(child.compact)

    # Fill remaining positions with parent2 genes in order
    fill_idx = 0
    p2_genes.each do |gene|
      next if used.include?(gene)

      # Find next nil position
      fill_idx += 1 while child[fill_idx]
      child[fill_idx] = gene
    end

    build_full_order(child, start_track, end_track)
  end

  def mutate(order, rate, start_track, end_track)
    return order if rand > rate

    mutable = remove_locked_tracks(order, start_track, end_track)
    return order if mutable.size < 2

    # Swap two random positions
    idx1 = rand(0...mutable.size)
    idx2 = rand(0...mutable.size)
    mutable[idx1], mutable[idx2] = mutable[idx2], mutable[idx1]

    build_full_order(mutable, start_track, end_track)
  end

  def tournament_select(elite, tournament_size = 3)
    tournament = elite.sample([tournament_size, elite.size].min)
    tournament.max_by { |i| i[:score] }[:order]
  end

  # ===============================
  # ALGORITHM 3: GREEDY WITH LOOKAHEAD (26+ tracks)
  # ===============================

  def greedy_with_lookahead(tracks, opts)
    start_track = opts[:start_with]
    end_track = opts[:end_with]
    lookahead = opts[:lookahead] || 3

    ordered = start_track ? [start_track] : []
    remaining = (tracks - ordered - [end_track].compact).to_set

    while remaining.any?
      current = ordered.last || tracks.first

      # Try each remaining track and look ahead
      best_next = nil
      best_score = -Float::INFINITY

      remaining.each do |candidate|
        immediate_score = score_transition(current, candidate, opts)

        # Look ahead: what opportunities does this create?
        future_score = estimate_future_potential(
          candidate,
          remaining,
          candidate,
          lookahead - 1,
          opts
        )

        total = immediate_score + (future_score * 0.5) # Weight future less

        if total > best_score
          best_score = total
          best_next = candidate
        end
      end

      ordered << best_next
      remaining.delete(best_next)
    end

    ordered << end_track if end_track

    {
      order: ordered,
      score: score_arrangement(ordered, opts),
      method: "greedy_lookahead"
    }
  end

  def estimate_future_potential(track, remaining_set, exclude_track, depth, opts)
    return 0 if depth.zero? || remaining_set.size <= 1

    # Quick heuristic: average of best few transitions from here
    # Avoid allocating array - just track top 3 scores
    top_scores = []
    remaining_set.each do |t|
      next if t == exclude_track

      score = score_transition(track, t, opts)
      top_scores << score
      top_scores.sort!.reverse!
      top_scores.pop if top_scores.size > 3
    end

    return 0 if top_scores.empty?

    top_scores.sum / top_scores.size.to_f
  end
end
# rubocop:enable Metrics/ClassLength
