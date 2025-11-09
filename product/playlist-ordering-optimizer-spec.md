# Playlist Ordering Optimizer - Feature Specification

**Status:** 📋 Planned
**Priority:** Medium (depends on Harmonic Scoring System v2.0)
**Estimated Effort:** 12-20 hours
**Created:** 2025-11-07

## Overview
Automatic playlist ordering optimization that finds the best arrangement of tracks to maximize harmonic flow and energy progression. Uses different algorithms based on playlist size to balance computation time with result quality.

## Dependencies
**CRITICAL:** This feature requires **Harmonic Scoring System v2.0** to be implemented first. The optimizer uses the new scoring system that rewards variety and skill over simple key matching.

## Problem Statement

### User Pain Points
1. **Manual ordering is tedious**: DJs spend hours reordering 20-25 track sets
2. **Suboptimal results**: Easy to miss better arrangements when ordering by hand
3. **No energy arc guidance**: Hard to visualize energy progression when looking at a flat track list
4. **Multiple goals conflict**: Harmonic compatibility vs. energy progression vs. personal preferences

### User Story
> "As a DJ, when I've selected 20 tracks for my set, I want the system to automatically find the best order that maximizes harmonic flow and creates a good energy arc, so I can spend less time on tedious reordering and more time on creative decisions."

## Algorithm Complexity Analysis

### The Challenge: Traveling Salesman Problem (TSP)
Finding the optimal track order is equivalent to TSP - we need to visit all tracks once and maximize total transition quality.

**Brute Force Complexity:** O(N!) - factorial time

| Tracks (N) | Permutations        | Estimated Time      | Feasibility |
|------------|---------------------|---------------------|-------------|
| 5          | 120                 | Instant             | ✅ Easy     |
| 8          | 40,320              | < 1 second          | ✅ Easy     |
| 10         | 3,628,800           | ~1-2 seconds        | ✅ OK       |
| 12         | 479,001,600         | ~2-5 minutes        | ⚠️ Slow     |
| 15         | 1,307,674,368,000   | ~2 weeks            | ❌ No       |
| 20         | 2.43 × 10¹⁸         | ~77,000 years       | ❌ No       |
| 25         | 1.55 × 10²⁵         | Heat death of universe | ❌ No   |

**Conclusion:** We need multiple algorithms - brute force only works up to ~10 tracks.

## Multi-Algorithm Strategy

### Tiered Approach Based on Playlist Size

```ruby
def optimize_order(tracks, options = {})
  case tracks.count
  when 0..1
    tracks  # Nothing to optimize
  when 2..10
    brute_force_optimal(tracks, options)      # Guaranteed optimal
  when 11..15
    branch_and_bound_optimal(tracks, options) # Near-optimal, faster
  when 16..25
    genetic_algorithm(tracks, options)        # Very good, ~10-30 sec
  else
    greedy_with_lookahead(tracks, options)    # Fast fallback
  end
end
```

### Algorithm 1: Brute Force (2-10 tracks)
**Complexity:** O(N!)
**Time:** 1-3 seconds for 10 tracks
**Quality:** 100% optimal - guaranteed best result

```ruby
def brute_force_optimal(tracks, options = {})
  start_track = options[:start_with]
  end_track = options[:end_with]
  
  candidates = apply_constraints(tracks, start_track, end_track)
  
  best_order = nil
  best_score = -Float::INFINITY
  
  candidates.permutation.each do |order|
    full_order = build_full_order(order, start_track, end_track)
    score = score_arrangement(full_order, options)
    
    if score > best_score
      best_score = score
      best_order = full_order
    end
  end
  
  { order: best_order, score: best_score, method: 'brute_force' }
end
```

**Pros:**
- Guaranteed optimal solution
- Simple to implement and debug
- Trustworthy results

**Cons:**
- Only works for small playlists (≤10 tracks)
- Time grows factorially

### Algorithm 2: Branch and Bound (11-15 tracks)
**Complexity:** O(N!) worst case, but much faster in practice with pruning
**Time:** 5-30 seconds for 15 tracks
**Quality:** 95-100% optimal (often finds optimal, sometimes near-optimal)

```ruby
def branch_and_bound_optimal(tracks, options = {})
  start_track = options[:start_with]
  end_track = options[:end_with]
  
  @best_score = -Float::INFINITY
  @best_order = nil
  @bounds_pruned = 0
  
  candidates = apply_constraints(tracks, start_track, end_track)
  
  # Start recursive search
  branch_and_bound_search(
    current_order: [start_track].compact,
    remaining: candidates,
    current_score: 0,
    options: options
  )
  
  full_order = build_full_order(@best_order, start_track, end_track)
  
  {
    order: full_order,
    score: @best_score,
    method: 'branch_and_bound',
    branches_pruned: @bounds_pruned
  }
end

def branch_and_bound_search(current_order:, remaining:, current_score:, options:)
  # Base case: all tracks placed
  if remaining.empty?
    if current_score > @best_score
      @best_score = current_score
      @best_order = current_order.dup
    end
    return
  end
  
  # Calculate optimistic upper bound for this branch
  upper_bound = current_score + optimistic_remaining_score(
    current_order.last,
    remaining,
    options
  )
  
  # Prune this branch if it can't beat current best
  if upper_bound <= @best_score
    @bounds_pruned += 1
    return
  end
  
  # Try each remaining track
  remaining.each do |next_track|
    transition_score = score_transition(
      current_order.last,
      next_track,
      options
    )
    
    branch_and_bound_search(
      current_order: current_order + [next_track],
      remaining: remaining - [next_track],
      current_score: current_score + transition_score,
      options: options
    )
  end
end

def optimistic_remaining_score(current_track, remaining_tracks, options)
  # Assume we can make perfect transitions for all remaining tracks
  # This gives us an upper bound that's always >= actual achievable score
  remaining_tracks.count * 3  # Max score per transition
end
```

**Pros:**
- Often finds optimal solution
- Much faster than pure brute force
- Good for 11-15 track range

**Cons:**
- Still can be slow (worst case same as brute force)
- Complex to implement correctly

### Algorithm 3: Genetic Algorithm (16-25 tracks)
**Complexity:** O(N² × generations × population_size)
**Time:** 10-30 seconds for 25 tracks
**Quality:** 85-95% optimal (very good, not guaranteed optimal)

```ruby
def genetic_algorithm(tracks, options = {})
  generations = options[:generations] || 1000
  population_size = options[:population_size] || 100
  mutation_rate = options[:mutation_rate] || 0.1
  
  start_track = options[:start_with]
  end_track = options[:end_with]
  
  # Initialize population with random orderings
  population = initialize_population(
    tracks,
    population_size,
    start_track,
    end_track
  )
  
  best_ever = { order: nil, score: -Float::INFINITY }
  
  generations.times do |gen|
    # Score all individuals
    scored_population = population.map do |order|
      { order: order, score: score_arrangement(order, options) }
    end
    
    # Track best
    generation_best = scored_population.max_by { |i| i[:score] }
    if generation_best[:score] > best_ever[:score]
      best_ever = generation_best
    end
    
    # Selection: Keep top 20%
    elite_size = (population_size * 0.2).to_i
    elite = scored_population.sort_by { |i| -i[:score] }.first(elite_size)
    
    # Reproduction: Generate new population
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
    method: 'genetic_algorithm',
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

def crossover(parent1, parent2, start_track, end_track)
  # Ordered Crossover (OX): preserve relative order from both parents
  # This is specifically designed for permutation problems
  
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
  
  # Fill remaining positions with parent2 genes in order
  p2_genes.each do |gene|
    next if child.include?(gene)
    child[child.index(nil)] = gene
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
  tournament = elite.sample(tournament_size)
  tournament.max_by { |i| i[:score] }[:order]
end
```

**Pros:**
- Handles large playlists (16-25 tracks)
- Reasonable computation time (10-30 seconds)
- Results are very good (85-95% optimal)
- Configurable (can trade time for quality)

**Cons:**
- Not guaranteed optimal
- Results vary between runs
- More complex to implement

### Algorithm 4: Greedy with Lookahead (26+ tracks, fallback)
**Complexity:** O(N² × lookahead_depth)
**Time:** 1-3 seconds for any size
**Quality:** 70-85% optimal (decent, not great)

```ruby
def greedy_with_lookahead(tracks, options = {})
  start_track = options[:start_with]
  end_track = options[:end_with]
  lookahead = options[:lookahead] || 3
  
  ordered = start_track ? [start_track] : []
  remaining = tracks - ordered - [end_track].compact
  
  while remaining.any?
    current = ordered.last || tracks.first
    
    # Try each remaining track and look ahead
    best_next = nil
    best_score = -Float::INFINITY
    
    remaining.each do |candidate|
      immediate_score = score_transition(current, candidate, options)
      
      # Look ahead: what opportunities does this create?
      future_score = estimate_future_potential(
        candidate,
        remaining - [candidate],
        lookahead - 1,
        options
      )
      
      total = immediate_score + (future_score * 0.5)  # Weight future less
      
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
    score: score_arrangement(ordered, options),
    method: 'greedy_lookahead'
  }
end

def estimate_future_potential(track, remaining, depth, options)
  return 0 if depth == 0 || remaining.empty?
  
  # Quick heuristic: average of best few transitions from here
  scores = remaining.map { |t| score_transition(track, t, options) }
  scores.max(3).sum / 3.0
end
```

**Pros:**
- Very fast (1-3 seconds)
- Works for any playlist size
- Simple to understand
- Decent results

**Cons:**
- Not optimal (70-85% quality)
- Can get stuck in local optima
- Lookahead depth limited by performance

## Energy Arc Scoring

### Implementation Summary

**Energy Estimation Method:** BPM + Key Mode (uses existing data, no new DB fields)

| Input Data | Weight | How It Works |
|------------|--------|--------------|
| **BPM** | 80% | Higher BPM = higher energy (80-160 BPM → 0-80 points) |
| **Key Mode** | 20% | Major keys (B) get +20 bonus for brightness |

**Examples:**
- 128 BPM, 8A (minor) → Energy: 48
- 128 BPM, 8B (major) → Energy: 68
- 145 BPM, 12B (major) → Energy: 85

**Why This Works:** Electronic music energy correlates strongly with BPM, and major keys psychoacoustically sound brighter. This simple formula requires zero new data collection.

---

### The Energy Curve Problem
Harmonic flow alone isn't enough - DJs need energy progression:
1. **Start**: Mid-energy (engage crowd)
2. **Build**: Gradual increase
3. **Peak**: 60-70% through set (climax)
4. **Wind down**: Gradually decrease

### Example: Why Energy Arc Matters

**Bad Arc (Random Energy):**
```
Track 1: 145 BPM → Track 2: 95 BPM → Track 3: 140 BPM
(High energy crash, then jarring jump back up)
```

**Good Arc (Intentional Progression):**
```
Track 1: 120 BPM → Track 2: 125 BPM → Track 3: 130 BPM → Track 4: 125 BPM
(Smooth build to peak, then gentle cool down)
```

### Energy Estimation from BPM + Key Mode

We estimate track energy using data we already have:
- **BPM**: Higher BPM = higher energy (primary factor, 80% of score)
- **Key Mode**: Major keys (B) feel brighter/higher energy than minor (A) (+20 bonus)

```ruby
def estimate_track_energy(track)
  # Base energy from BPM (80-160 BPM range typical for electronic music)
  # Maps to 0-80 score
  bpm_energy = ((track.bpm - 80) / 80.0 * 80).clamp(0, 80)
  
  # Major keys (B) get brightness bonus
  key_mode_bonus = track.key.name.end_with?('B') ? 20 : 0
  
  # Combine (max 100)
  (bpm_energy + key_mode_bonus).clamp(0, 100)
end
```

**Examples:**
```
Track at 128 BPM in 8A (minor): 
  BPM energy = 48, Key bonus = 0  → Total = 48

Track at 128 BPM in 8B (major):
  BPM energy = 48, Key bonus = 20 → Total = 68

Track at 145 BPM in 12A (minor):
  BPM energy = 65, Key bonus = 0  → Total = 65

Track at 145 BPM in 12B (major):
  BPM energy = 65, Key bonus = 20 → Total = 85
```

**Why This Works:**
- Electronic music energy correlates strongly with BPM
- Major keys (B) psychoacoustically sound "brighter" and more energetic
- Simple, deterministic, uses only existing data (no new DB fields needed)

### Ideal Energy Curve Generator

The optimizer compares actual energy progression against an ideal curve:

```ruby
def ideal_energy_curve(track_count)
  # Generate ideal energy values for each position in the set
  # Returns array of 0-100 energy values
  
  (0...track_count).map do |i|
    position = i.to_f / track_count  # 0.0 to 1.0
    
    case position
    when 0.0..0.1    # Opening (0-10%): Ease in at mid-energy
      40 + (position * 100)           # 40 → 50
      
    when 0.1..0.6    # Build (10-60%): Steady climb
      50 + ((position - 0.1) * 100)   # 50 → 100
      
    when 0.6..0.7    # Peak (60-70%): Maximum energy
      100
      
    when 0.7..0.9    # Drop (70-90%): Cool down
      100 - ((position - 0.7) * 250)  # 100 → 50
      
    else             # Closing (90-100%): Wind down
      50 - ((position - 0.9) * 400)   # 50 → 10
    end.clamp(0, 100)
  end
end
```

**Visual representation for 10-track set:**
```
Position  Ideal Energy
────────  ────────────
   0%        40  (ease in)
  10%        50  ┐
  20%        60  │
  30%        70  │ Build
  40%        80  │
  50%        90  ┘
  60%       100  ← Peak!
  70%        75  ┐
  80%        50  │ Cool down
  90%        30  │
 100%        10  ┘ Close
```

### Energy Arc Score Calculation

Compare actual energy progression to the ideal curve:

```ruby
def energy_arc_score(ordered_tracks)
  return 100 if ordered_tracks.count < 3  # Too short to judge
  
  # Get actual energy values
  actual_energies = ordered_tracks.map { |t| estimate_track_energy(t) }
  
  # Get ideal curve for this playlist length
  ideal_energies = ideal_energy_curve(ordered_tracks.count)
  
  # Calculate Mean Squared Error (lower = better match)
  squared_errors = actual_energies.zip(ideal_energies).map do |actual, ideal|
    (actual - ideal) ** 2
  end
  
  mse = squared_errors.sum / actual_energies.count
  
  # Convert MSE to 0-100 score (inverse relationship)
  # Max possible MSE = 10,000 (100 points difference squared)
  # Perfect match MSE = 0
  max_mse = 10_000
  similarity = 1 - (mse / max_mse)
  
  (similarity * 100).clamp(0, 100)
end
```

**Example Calculation:**

```ruby
# 5-track playlist
actual =  [45, 60, 85, 70, 30]  # Actual track energies
ideal =   [45, 62, 88, 75, 25]  # Ideal curve values

# Squared errors
errors = [(45-45)², (60-62)², (85-88)², (70-75)², (30-25)²]
       = [0, 4, 9, 25, 25]

mse = (0 + 4 + 9 + 25 + 25) / 5 = 12.6

score = (1 - (12.6 / 10000)) * 100 = 99.87
# ≈ 100/100 - Very close to ideal!
```

**What Makes a Good Energy Arc Score:**
- **90-100**: Excellent - follows ideal curve closely
- **75-89**: Good - general energy progression is right
- **60-74**: Decent - some progression but rough spots
- **Below 60**: Poor - energy all over the place

### Combined Scoring

The optimizer balances harmonic quality with energy progression:

```ruby
def score_arrangement(ordered_tracks, options = {})
  harmonic_weight = options[:harmonic_weight] || 0.7  # Default: 70%
  energy_weight = options[:energy_weight] || 0.3      # Default: 30%
  
  # Score 1: Harmonic transitions (using new scoring system v2.0)
  harmonic_score = SetAnalysisService.new(ordered_tracks).score
  
  # Score 2: How well does energy follow ideal curve?
  energy_score = energy_arc_score(ordered_tracks)
  
  # Weighted combination
  (harmonic_score * harmonic_weight) + (energy_score * energy_weight)
end
```

**Weight Configuration:**

Users can adjust the balance via UI controls (see Optimization Options Modal):

| Setting | Harmonic % | Energy % | Best For |
|---------|-----------|----------|----------|
| **Harmonic Focus** | 90% | 10% | Pure key compatibility, ignore energy flow |
| **Balanced** (default) | 70% | 30% | Good mix of both considerations |
| **Energy Focus** | 50% | 50% | Equal weight to energy progression |
| **Energy Only** | 30% | 70% | Prioritize energy arc over keys |

**Disable Energy Arc Entirely:**
```ruby
# Set energy_weight to 0
optimizer = PlaylistOptimizerService.new(playlist, energy_weight: 0)
# Result: Pure harmonic optimization only
```

### Example: Why Energy Arc Matters

Consider two orderings of the same 5 tracks, both with **identical harmonic scores (90/100)**:

**Arrangement A (Harmonic-only optimization, energy_weight = 0):**
```
Track 1: 145 BPM, 8A  → Energy: 65  (high)
Track 2: 146 BPM, 9A  → Energy: 66  (high)
Track 3: 95 BPM, 10A  → Energy: 19  (low)   ← Sudden crash!
Track 4: 96 BPM, 11A  → Energy: 20  (low)
Track 5: 144 BPM, 12A → Energy: 64  (high)  ← Jarring jump!

Harmonic Score: 90/100
Energy Arc Score: 20/100 (terrible - all over the place)
Combined (70/30): (90 × 0.7) + (20 × 0.3) = 69/100
```

**Arrangement B (Balanced optimization, energy_weight = 0.3):**
```
Track 1: 120 BPM, 8A  → Energy: 40  (mid)    ← Ease in
Track 2: 128 BPM, 9A  → Energy: 48  (mid)    ← Build
Track 3: 145 BPM, 10A → Energy: 65  (high)   ← Peak!
Track 4: 135 BPM, 11A → Energy: 55  (mid)    ← Cool down
Track 5: 118 BPM, 12A → Energy: 38  (mid)    ← Close

Harmonic Score: 90/100
Energy Arc Score: 95/100 (excellent - smooth progression)
Combined (70/30): (90 × 0.7) + (95 × 0.3) = 91.5/100
```

**Result:** Arrangement B scores higher overall and **feels like a journey** rather than random tracks. The optimizer would choose B when energy weight > 0.

## User Interface

### 1. Playlist Show Page - "Optimize Order" Button

**Location:** `app/views/playlists/show.html.erb`

```erb
<div class="playlist-actions">
  <%= link_to "Edit Playlist", edit_playlist_path(@playlist), class: "btn btn-primary" %>
  
  <% if @playlist.playlist_tracks.count >= 2 %>
    <%= button_to "🎯 Optimize Order",
                  optimize_playlist_path(@playlist),
                  method: :post,
                  data: {
                    turbo_method: :post,
                    turbo_confirm: "This will reorder all tracks. Continue?"
                  },
                  class: "btn btn-success" %>
  <% end %>
</div>
```

### 2. Optimization Options Modal (Optional)

**Advanced users can configure:**
```erb
<div class="modal" id="optimizeModal">
  <div class="modal-dialog">
    <div class="modal-content">
      <div class="modal-header">
        <h5>Optimize Playlist Order</h5>
      </div>
      
      <div class="modal-body">
        <form action="<%= optimize_playlist_path(@playlist) %>" method="post">
          <%= hidden_field_tag :authenticity_token, form_authenticity_token %>
          
          <!-- Start track (optional) -->
          <div class="mb-3">
            <label>Start with (optional):</label>
            <%= select_tag :start_track_id,
                          options_from_collection_for_select(
                            @playlist.tracks,
                            :id,
                            :display_name,
                            nil
                          ),
                          include_blank: "Any track",
                          class: "form-select" %>
          </div>
          
          <!-- End track (optional) -->
          <div class="mb-3">
            <label>End with (optional):</label>
            <%= select_tag :end_track_id,
                          options_from_collection_for_select(
                            @playlist.tracks,
                            :id,
                            :display_name,
                            nil
                          ),
                          include_blank: "Any track",
                          class: "form-select" %>
          </div>
          
          <!-- Scoring weights -->
          <div class="mb-3">
            <label>Harmonic vs. Energy priority:</label>
            <input type="range" 
                   name="harmonic_weight" 
                   min="0" 
                   max="1" 
                   step="0.1" 
                   value="0.7"
                   class="form-range">
            <small class="text-muted">
              <span id="harmonic-pct">70</span>% Harmonic,
              <span id="energy-pct">30</span>% Energy
            </small>
          </div>
          
          <button type="submit" class="btn btn-primary">Optimize</button>
        </form>
      </div>
    </div>
  </div>
</div>
```

### 3. Progress Indicator (for genetic algorithm)

**For playlists 16+ tracks, show progress:**
```erb
<div id="optimization-progress" class="d-none">
  <div class="progress">
    <div class="progress-bar progress-bar-striped progress-bar-animated"
         role="progressbar"
         style="width: 0%">
      Optimizing... 0%
    </div>
  </div>
  <p class="text-muted mt-2">
    Finding best arrangement... This may take 10-30 seconds.
  </p>
</div>
```

### 4. Results Display

**After optimization completes:**
```erb
<div class="alert alert-success">
  <h5>✨ Optimization Complete!</h5>
  <ul>
    <li>Method: <%= @optimization_result[:method].titleize %></li>
    <li>Score improved: <%= @old_score %> → <%= @new_score %> 
        (<%= @score_improvement %>% better)</li>
    <li>Computation time: <%= @computation_time %> seconds</li>
  </ul>
  
  <div class="mt-3">
    <%= link_to "Keep Changes", confirm_optimization_playlist_path(@playlist),
                method: :patch,
                class: "btn btn-success" %>
    <%= link_to "Revert", playlist_path(@playlist),
                class: "btn btn-outline-secondary" %>
  </div>
</div>
```

## Backend Implementation

### 1. New Service: `PlaylistOptimizerService`

**File:** `app/services/playlist_optimizer_service.rb`

```ruby
class PlaylistOptimizerService
  attr_reader :playlist, :options, :result
  
  def initialize(playlist, options = {})
    @playlist = playlist
    @options = default_options.merge(options)
    @result = nil
  end
  
  def optimize!
    tracks = playlist.tracks_in_order
    
    start_time = Time.current
    
    @result = optimize_order(tracks, options)
    @result[:computation_time] = Time.current - start_time
    @result[:old_score] = current_score
    @result[:score_improvement] = score_improvement_percentage
    
    @result
  end
  
  def apply!
    return false unless result
    
    result[:order].each_with_index do |track, index|
      playlist_track = playlist.playlist_tracks.find_by(track: track)
      playlist_track.update(order: index + 1)
    end
    
    playlist.touch  # Invalidate caches
    true
  end
  
  private
  
  def default_options
    {
      harmonic_weight: 0.7,
      energy_weight: 0.3,
      start_with: nil,
      end_with: nil,
      generations: 1000,        # For genetic algorithm
      population_size: 100,     # For genetic algorithm
      mutation_rate: 0.1,       # For genetic algorithm
      lookahead: 3              # For greedy algorithm
    }
  end
  
  def optimize_order(tracks, opts)
    case tracks.count
    when 0..1
      { order: tracks, score: 100, method: 'none' }
    when 2..10
      brute_force_optimal(tracks, opts)
    when 11..15
      branch_and_bound_optimal(tracks, opts)
    when 16..25
      genetic_algorithm(tracks, opts)
    else
      greedy_with_lookahead(tracks, opts)
    end
  end
  
  def current_score
    SetAnalysisService.new(playlist.tracks_in_order).score
  end
  
  def score_improvement_percentage
    return 0 if result[:old_score].zero?
    ((result[:score] - result[:old_score]) / result[:old_score] * 100).round(1)
  end
  
  # Algorithm implementations...
  # (brute_force_optimal, branch_and_bound_optimal, genetic_algorithm, etc.)
end
```

### 2. Update `Playlist` Model

**File:** `app/models/playlist.rb`

```ruby
class Playlist < ApplicationRecord
  has_many :playlist_tracks, -> { order(:order) }
  has_many :tracks, through: :playlist_tracks
  
  # New method
  def tracks_in_order
    playlist_tracks.includes(:track).order(:order).map(&:track)
  end
  
  # New method
  def optimize_order!(options = {})
    optimizer = PlaylistOptimizerService.new(self, options)
    result = optimizer.optimize!
    optimizer.apply!
    result
  end
end
```

### 3. Controller Actions

**File:** `app/controllers/playlists_controller.rb`

```ruby
class PlaylistsController < ApplicationController
  # New action
  def optimize
    @playlist = Playlist.find(params[:id])
    
    # Store current order in session (for revert)
    session[:pre_optimization_order] = @playlist.playlist_tracks
                                               .order(:order)
                                               .pluck(:track_id)
    
    options = optimization_params
    @result = @playlist.optimize_order!(options)
    
    flash[:success] = "Playlist optimized! Score: #{@result[:old_score]} → #{@result[:score]}"
    redirect_to playlist_path(@playlist)
    
  rescue StandardError => e
    flash[:error] = "Optimization failed: #{e.message}"
    redirect_to playlist_path(@playlist)
  end
  
  # New action (optional)
  def revert_optimization
    @playlist = Playlist.find(params[:id])
    previous_order = session[:pre_optimization_order]
    
    if previous_order
      previous_order.each_with_index do |track_id, index|
        playlist_track = @playlist.playlist_tracks.find_by(track_id: track_id)
        playlist_track.update(order: index + 1)
      end
      
      session.delete(:pre_optimization_order)
      flash[:success] = "Reverted to previous order"
    else
      flash[:error] = "No previous order found"
    end
    
    redirect_to playlist_path(@playlist)
  end
  
  private
  
  def optimization_params
    params.permit(
      :start_track_id,
      :end_track_id,
      :harmonic_weight,
      :energy_weight
    ).to_h.symbolize_keys.tap do |opts|
      opts[:start_with] = Track.find(opts.delete(:start_track_id)) if opts[:start_track_id].present?
      opts[:end_with] = Track.find(opts.delete(:end_track_id)) if opts[:end_track_id].present?
      opts[:harmonic_weight] = opts[:harmonic_weight].to_f if opts[:harmonic_weight]
      opts[:energy_weight] = 1.0 - opts[:harmonic_weight] if opts[:harmonic_weight]
    end
  end
end
```

### 4. Routes

**File:** `config/routes.rb`

```ruby
resources :playlists do
  member do
    post :optimize
    patch :revert_optimization
  end
end
```

## Performance Optimization

### Background Job Processing (Recommended for 16+ tracks)

**Use Sidekiq/Delayed Job for longer operations:**

```ruby
# app/jobs/playlist_optimization_job.rb
class PlaylistOptimizationJob < ApplicationJob
  queue_as :default
  
  def perform(playlist_id, options = {})
    playlist = Playlist.find(playlist_id)
    result = playlist.optimize_order!(options)
    
    # Broadcast result via ActionCable
    ActionCable.server.broadcast(
      "playlist_#{playlist_id}",
      {
        type: 'optimization_complete',
        result: result
      }
    )
  end
end

# In controller:
def optimize
  @playlist = Playlist.find(params[:id])
  
  if @playlist.tracks.count >= 16
    # Queue background job
    PlaylistOptimizationJob.perform_later(@playlist.id, optimization_params)
    flash[:info] = "Optimization started in background. You'll be notified when complete."
  else
    # Run immediately
    @result = @playlist.optimize_order!(optimization_params)
    flash[:success] = "Optimization complete!"
  end
  
  redirect_to playlist_path(@playlist)
end
```

### Caching
```ruby
# Cache optimization results
def optimize_order(tracks, opts)
  cache_key = "playlist_optimization_#{cache_key_string(tracks, opts)}"
  
  Rails.cache.fetch(cache_key, expires_in: 1.hour) do
    # Run optimization...
  end
end

def cache_key_string(tracks, opts)
  track_ids = tracks.map(&:id).sort.join('-')
  options_hash = opts.slice(:start_with, :end_with, :harmonic_weight).to_s
  Digest::MD5.hexdigest("#{track_ids}_#{options_hash}")
end
```

## Testing Strategy

### Unit Tests

**File:** `test/services/playlist_optimizer_service_test.rb`

```ruby
require 'test_helper'

class PlaylistOptimizerServiceTest < ActiveSupport::TestCase
  setup do
    @playlist = create_playlist_with_keys(
      ["8A", "9A", "10A", "11A", "12A", "1A", "2A", "3A"]
    )
  end
  
  test "brute_force_optimal finds best arrangement for 8 tracks" do
    optimizer = PlaylistOptimizerService.new(@playlist)
    result = optimizer.optimize!
    
    assert_equal 'brute_force', result[:method]
    assert result[:score] >= 80, "Should find high-quality arrangement"
    assert_equal @playlist.tracks.count, result[:order].count
  end
  
  test "respects start_with constraint" do
    start_track = @playlist.tracks.first
    optimizer = PlaylistOptimizerService.new(@playlist, start_with: start_track)
    result = optimizer.optimize!
    
    assert_equal start_track, result[:order].first
  end
  
  test "respects end_with constraint" do
    end_track = @playlist.tracks.last
    optimizer = PlaylistOptimizerService.new(@playlist, end_with: end_track)
    result = optimizer.optimize!
    
    assert_equal end_track, result[:order].last
  end
  
  test "genetic_algorithm completes for 20 tracks" do
    large_playlist = create_playlist_with_tracks(20)
    optimizer = PlaylistOptimizerService.new(large_playlist)
    
    result = nil
    time = Benchmark.measure do
      result = optimizer.optimize!
    end
    
    assert_equal 'genetic_algorithm', result[:method]
    assert time.real < 60, "Should complete in under 60 seconds"
    assert result[:score] > 0
  end
  
  test "apply! reorders playlist_tracks correctly" do
    optimizer = PlaylistOptimizerService.new(@playlist)
    optimizer.optimize!
    
    old_order = @playlist.tracks_in_order.map(&:id)
    optimizer.apply!
    new_order = @playlist.reload.tracks_in_order.map(&:id)
    
    # Order should change (unless already optimal)
    assert_not_equal old_order, new_order unless optimizer.result[:score] == 100
    
    # But should contain same tracks
    assert_equal old_order.sort, new_order.sort
  end
  
  test "energy arc scoring rewards good energy progression" do
    # Tracks with good energy arc: 100 → 120 → 140 → 130 → 110 BPM
    good_arc_tracks = [
      create(:track, bpm: 100, key: create(:key, name: "8A")),
      create(:track, bpm: 120, key: create(:key, name: "9A")),
      create(:track, bpm: 140, key: create(:key, name: "10A")),
      create(:track, bpm: 130, key: create(:key, name: "11A")),
      create(:track, bpm: 110, key: create(:key, name: "12A"))
    ]
    
    # Tracks with chaotic energy: 140 → 90 → 145 → 95 → 135 BPM
    chaotic_tracks = [
      create(:track, bpm: 140, key: create(:key, name: "8A")),
      create(:track, bpm: 90, key: create(:key, name: "9A")),
      create(:track, bpm: 145, key: create(:key, name: "10A")),
      create(:track, bpm: 95, key: create(:key, name: "11A")),
      create(:track, bpm: 135, key: create(:key, name: "12A"))
    ]
    
    good_score = energy_arc_score(good_arc_tracks)
    chaotic_score = energy_arc_score(chaotic_tracks)
    
    assert good_score > chaotic_score, 
           "Good energy arc should score higher than chaotic"
    assert good_score > 80, "Good arc should score 80+"
    assert chaotic_score < 60, "Chaotic arc should score below 60"
  end
  
  test "energy_weight affects optimization results" do
    playlist = create_playlist_with_varying_bpms
    
    # Optimize with harmonic-only (energy weight = 0)
    harmonic_only = PlaylistOptimizerService.new(
      playlist, 
      energy_weight: 0
    ).optimize!
    
    # Optimize with balanced weights
    balanced = PlaylistOptimizerService.new(
      playlist,
      harmonic_weight: 0.7,
      energy_weight: 0.3
    ).optimize!
    
    # Orders might differ when energy arc is considered
    # (Not guaranteed, but likely with varied BPMs)
    refute_equal harmonic_only[:order].map(&:id), 
                 balanced[:order].map(&:id),
                 "Energy weight should potentially change ordering"
  end
  
  test "major keys get energy bonus over minor keys" do
    track_major = create(:track, bpm: 128, key: create(:key, name: "8B"))
    track_minor = create(:track, bpm: 128, key: create(:key, name: "8A"))
    
    energy_major = estimate_track_energy(track_major)
    energy_minor = estimate_track_energy(track_minor)
    
    assert_equal 20, energy_major - energy_minor,
                 "Major key should have +20 energy bonus"
  end
end
```

### Integration Tests

**File:** `test/integration/playlist_optimization_test.rb`

```ruby
require 'test_helper'

class PlaylistOptimizationTest < ActionDispatch::IntegrationTest
  setup do
    @user = login_as_user
    @playlist = create(:playlist, user: @user)
    10.times { @playlist.tracks << create(:track) }
  end
  
  test "user can optimize playlist from show page" do
    get playlist_path(@playlist)
    assert_response :success
    assert_select 'button', text: /Optimize Order/
    
    post optimize_playlist_path(@playlist)
    assert_redirected_to playlist_path(@playlist)
    
    follow_redirect!
    assert_match /optimized/i, flash[:success]
  end
  
  test "optimization button hidden for playlists with <2 tracks" do
    @playlist.tracks.destroy_all
    
    get playlist_path(@playlist)
    assert_select 'button', text: /Optimize Order/, count: 0
  end
end
```

### Performance Benchmarking

**File:** `test/performance/playlist_optimizer_performance_test.rb`

```ruby
require 'test_helper'
require 'benchmark'

class PlaylistOptimizerPerformanceTest < ActiveSupport::TestCase
  [5, 8, 10, 12, 15, 20, 25].each do |track_count|
    test "optimization performance for #{track_count} tracks" do
      playlist = create_playlist_with_tracks(track_count)
      optimizer = PlaylistOptimizerService.new(playlist)
      
      time = Benchmark.measure do
        optimizer.optimize!
      end
      
      expected_time = case track_count
        when 0..10  then 5    # 5 seconds
        when 11..15 then 30   # 30 seconds
        when 16..25 then 60   # 60 seconds
        else 120              # 2 minutes
      end
      
      assert time.real < expected_time,
             "Expected #{track_count} tracks to complete in <#{expected_time}s, took #{time.real.round(2)}s"
      
      puts "\n#{track_count} tracks: #{time.real.round(2)}s (#{optimizer.result[:method]})"
    end
  end
end
```

## Recommended Implementation Limits

### Hard Limits
```ruby
# In PlaylistOptimizerService

MAX_TRACKS_FOR_OPTIMIZATION = 50
MIN_TRACKS_FOR_OPTIMIZATION = 2

def validate!
  if playlist.tracks.count < MIN_TRACKS_FOR_OPTIMIZATION
    raise "Playlist must have at least #{MIN_TRACKS_FOR_OPTIMIZATION} tracks"
  end
  
  if playlist.tracks.count > MAX_TRACKS_FOR_OPTIMIZATION
    raise "Playlist too large (max #{MAX_TRACKS_FOR_OPTIMIZATION} tracks)"
  end
end
```

### Soft Warnings
```erb
<!-- In view -->
<% if @playlist.tracks.count > 25 %>
  <div class="alert alert-warning">
    ⚠️ This playlist has <%= @playlist.tracks.count %> tracks.
    Optimization may take 1-2 minutes and results are not guaranteed optimal.
    Consider breaking into smaller playlists for better results.
  </div>
<% end %>
```

## Future Enhancements (Out of Scope)

1. **Multi-objective optimization**: Sliders for harmonic/energy/genre variety
2. **Manual locking**: Let users lock specific tracks at specific positions
3. **Comparison mode**: Show before/after side-by-side
4. **Export optimization report**: PDF showing why tracks were ordered this way
5. **"Undo stack"**: Keep last 5 optimization attempts for comparison
6. **BPM constraints**: Ensure no >10% BPM jumps
7. **Genre flow**: Prefer smooth genre transitions
8. **Machine learning**: Learn from user's manual reorderings

## Open Questions & Decisions Needed

1. **Should we implement background jobs immediately or Phase 2?**
   - Recommendation: Start synchronous, add background jobs if users complain
   
2. **Should optimization be reversible?**
   - Recommendation: Yes - store previous order in session for 1-click revert
   
3. **Should we show algorithm choice to users?**
   - Recommendation: No - auto-select based on playlist size (keep it simple)
   
4. **~~Energy arc: How important vs. harmonic flow?~~** ✅ **DECIDED**
   - **Decision:** Default 70/30 (harmonic/energy), let advanced users adjust via slider
   - **Energy Estimation:** BPM + Key Mode (80% from BPM, 20% from major/minor)
   - **Users can disable:** Set energy_weight to 0 for pure harmonic optimization
   
5. **Should we limit optimization to playlist owner only?**
   - Recommendation: Yes - could add "suggest reorder" for collaborators later
   
6. **Should we cache optimization results?**
   - Recommendation: Yes, cache by track IDs + options hash for 1 hour
   - Invalidate on playlist track changes

## Success Metrics

### Immediate (Post-Deploy)
- ✅ All algorithms work correctly
- ✅ Performance benchmarks met
- ✅ No data loss (all tracks preserved)

### Short-term (1-2 weeks)
- 📊 % of playlists optimized
- 📊 Average score improvement
- 📊 User satisfaction with results
- 📊 Computation times by playlist size

### Long-term (1+ month)
- 📊 Do users keep optimized orderings or manually revert?
- 📊 Do users optimize multiple times (tweaking options)?
- 📊 Correlation between optimized playlists and engagement

## Dependencies & Prerequisites

### Must Be Completed First
1. ✅ **Harmonic Scoring System v2.0** - This spec depends on new scoring
2. ✅ `SetAnalysisService` - For scoring arrangements

### Optional But Recommended
- [ ] Background job system (Sidekiq/Delayed Job) - For 16+ track playlists
- [ ] ActionCable - For real-time progress updates

## Data Requirements

### Required Fields (Already Exist)
The optimizer uses **only existing data** - no new database fields needed:

| Field | Location | Used For |
|-------|----------|----------|
| `tracks.bpm` | Track model | Energy estimation (80% of energy score) |
| `keys.name` | Key model via Track | Harmonic compatibility + Energy bonus (20%) |
| `playlist_tracks.order` | PlaylistTrack join | Current order & result storage |

### Energy Calculation Breakdown
```ruby
# All from existing data:
bpm_energy = ((track.bpm - 80) / 80.0 * 80).clamp(0, 80)    # Uses tracks.bpm
key_bonus = track.key.name.end_with?('B') ? 20 : 0           # Uses keys.name
total_energy = (bpm_energy + key_bonus).clamp(0, 100)
```

**No migrations required!** ✅

### Future Enhancements (Optional New Fields)
These are **NOT** required for initial implementation:

- `tracks.energy_level` (integer 1-5) - Manual energy rating by DJ
- `tracks.genre` (string) - Could refine energy estimation
- `optimization_logs` table - Track optimization history for analytics

## Rollout Strategy

### Phase 1: Core Optimization (This Spec)
1. Implement algorithms (brute force, genetic)
2. Add `PlaylistOptimizerService`
3. Add controller actions + routes
4. Add UI button on playlist show page
5. Basic testing

**Estimated Time:** 12-15 hours

### Phase 2: Polish & Optimization
1. Add background job processing
2. Add progress indicators
3. Add revert functionality
4. Advanced options modal
5. Comprehensive testing

**Estimated Time:** 5-8 hours

### Phase 3: Advanced Features (Future)
1. Manual track locking
2. Multi-objective sliders
3. Export optimization reports
4. A/B comparison view

**Estimated Time:** 10-15 hours

---

**Created:** 2025-11-07
**Depends On:** `harmonic-scoring-system-spec.md`
**Ready for Implementation:** ⏳ After scoring system v2.0 is complete
