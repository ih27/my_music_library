# Harmonic Scoring System v2.0 - Feature Specification

**Status:** 📋 Planned
**Priority:** High (prerequisite for playlist ordering feature)
**Estimated Effort:** 4-6 hours
**Created:** 2025-11-07

## Overview
Revised harmonic scoring system that rewards **DJ craft quality** and **musical variety** rather than simple key matching. The current system scores same-key transitions highest (100 for all-same-key sets), which is musically boring. This revision values smooth transitions, intentional energy shifts, and variety over safe same-key mixing.

## Problem Statement

### Current Issues
1. **Same-key bias**: A playlist of 10 tracks in 8A scores 100/100, but is musically monotonous
2. **No energy consideration**: Doesn't account for energy progression or dramatic moments
3. **Doesn't reflect DJ skill**: Perfect matches require no skill; smooth transitions and energy boosts do
4. **Missing variety incentive**: No reward for creating musical journeys vs. playing it safe

### User Impact
- DJs can't distinguish between "boring but safe" and "skillfully crafted" sets
- Score doesn't correlate with actual mixing quality
- No guidance for creating dynamic, engaging sets

## Scoring Philosophy

### Core Principles
1. **Smooth transitions** (±1, relative major/minor) = Highest value - show skill and variety
2. **Energy boosts** (+7) = High value - intentional dramatic moments for peaks
3. **Perfect matches** (same key) = Moderate value - safe but less interesting
4. **Rough transitions** = Zero value - should be avoided

### Scoring Values
```
Transition Type          Points    Reasoning
─────────────────────────────────────────────────────────────
Smooth (±1, rel. maj/min)  3      Ideal: compatible + variety + skill
Energy Boost (+7)          3      Intentional energy management
Perfect Match (same key)   2      Safe but musically boring
Rough (incompatible)       0      Avoid these
```

## Implementation

### 1. Update `CamelotWheelService`

**File:** `app/services/camelot_wheel_service.rb`

#### New Method: `transition_score`
```ruby
# Returns numeric score for a transition (not just quality symbol)
def self.transition_score(from_key, to_key)
  quality = transition_quality(from_key, to_key)
  
  case quality
  when :perfect      then 2
  when :smooth       then 3
  when :energy_boost then 3
  when :rough        then 0
  end
end
```

#### Update: `harmonic_flow_score`
```ruby
# Current implementation uses weighted average
# New implementation uses point system
def self.harmonic_flow_score(transitions_array)
  return 100 if transitions_array.empty?
  
  total_score = transitions_array.sum do |transition|
    transition_score(transition[:from_key], transition[:to_key])
  end
  
  max_possible = transitions_array.count * 3
  ((total_score.to_f / max_possible) * 100).round
end
```

### 2. Add Consecutive Penalty System (Optional Enhancement)

#### New Service: `SetAnalysisService`

**File:** `app/services/set_analysis_service.rb`

```ruby
class SetAnalysisService
  # Analyze a set and provide detailed scoring with penalties/bonuses
  
  def initialize(ordered_tracks)
    @tracks = ordered_tracks
    @transitions = build_transitions
  end
  
  def score
    base_score - consecutive_penalty + variety_bonus
  end
  
  def detailed_analysis
    {
      base_score: base_score,
      consecutive_penalty: consecutive_penalty,
      variety_bonus: variety_bonus,
      final_score: score,
      insights: generate_insights
    }
  end
  
  private
  
  def base_score
    CamelotWheelService.harmonic_flow_score(@transitions)
  end
  
  def consecutive_penalty
    # Penalize 3+ consecutive perfect matches
    runs = find_consecutive_runs(:perfect)
    penalty = runs.select { |count| count >= 3 }.sum { |count| (count - 2) * 5 }
    [penalty, 30].min # Cap at 30 point penalty
  end
  
  def variety_bonus
    # Bonus for good mix of transition types
    types = @transitions.map { |t| t[:quality] }.uniq
    
    case types.count
    when 3..4 then 10  # Using 3-4 different transition types
    when 2    then 5   # Using 2 types
    else           0   # All same type or only 1 transition
    end
  end
  
  def find_consecutive_runs(quality_type)
    runs = []
    current_run = 0
    
    @transitions.each do |t|
      if t[:quality] == quality_type
        current_run += 1
      else
        runs << current_run if current_run > 0
        current_run = 0
      end
    end
    runs << current_run if current_run > 0
    
    runs
  end
  
  def generate_insights
    insights = []
    
    # Check for boring sections
    perfect_runs = find_consecutive_runs(:perfect)
    if perfect_runs.any? { |r| r >= 3 }
      insights << "⚠️ Multiple consecutive same-key transitions detected - consider adding variety"
    end
    
    # Check for rough transitions
    rough_count = @transitions.count { |t| t[:quality] == :rough }
    if rough_count > 0
      insights << "🟡 #{rough_count} rough transition(s) - consider reordering"
    end
    
    # Praise good variety
    types_used = @transitions.map { |t| t[:quality] }.uniq.count
    if types_used >= 3
      insights << "✨ Great variety of transition types!"
    end
    
    insights
  end
  
  def build_transitions
    return [] if @tracks.count < 2
    
    @tracks.each_cons(2).map do |from_track, to_track|
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
```

### 3. Update `Playlist` Model

**File:** `app/models/playlist.rb`

#### Update: `harmonic_flow_score`
```ruby
def harmonic_flow_score
  return 100 if playlist_tracks.count < 2
  
  transitions = analyze_transitions
  CamelotWheelService.harmonic_flow_score(transitions)
end

# Optional: Add detailed analysis method
def harmonic_analysis
  tracks_in_order = playlist_tracks.includes(:track).order(:order).map(&:track)
  SetAnalysisService.new(tracks_in_order).detailed_analysis
end
```

### 4. UI Updates

#### Playlist Show Page (`app/views/playlists/show.html.erb`)

**Add scoring breakdown section:**
```erb
<div class="harmonic-score-detail">
  <h4>Harmonic Analysis</h4>
  <div class="score-breakdown">
    <div class="base-score">
      Base Score: <%= @playlist.harmonic_flow_score %>
    </div>
    
    <% if @detailed_analysis %>
      <div class="score-details">
        <small class="text-muted">
          Base: <%= @detailed_analysis[:base_score] %>
          <% if @detailed_analysis[:consecutive_penalty] > 0 %>
            | Penalty: -<%= @detailed_analysis[:consecutive_penalty] %>
          <% end %>
          <% if @detailed_analysis[:variety_bonus] > 0 %>
            | Bonus: +<%= @detailed_analysis[:variety_bonus] %>
          <% end %>
        </small>
      </div>
      
      <% if @detailed_analysis[:insights].any? %>
        <div class="insights mt-2">
          <% @detailed_analysis[:insights].each do |insight| %>
            <div class="insight-item"><%= insight %></div>
          <% end %>
        </div>
      <% end %>
    <% end %>
  </div>
</div>
```

#### Playlist Index Page (`app/views/playlists/index.html.erb`)

**Update score badge to reflect new scoring:**
```erb
<!-- Keep existing badge, but update tooltip/title -->
<span class="badge harmonic-score <%= score_color_class(@playlist.harmonic_flow_score) %>"
      title="Harmonic Flow Score: <%= @playlist.harmonic_flow_score %>/100 (rewards variety and skill)">
  🎵 <%= @playlist.harmonic_flow_score %>
</span>
```

### 5. CSS Updates

**File:** `app/assets/stylesheets/application.bootstrap.scss`

```scss
// Score breakdown display
.harmonic-score-detail {
  background: #f8f9fa;
  border-radius: 8px;
  padding: 1rem;
  margin: 1rem 0;
  
  .score-breakdown {
    .base-score {
      font-size: 1.5rem;
      font-weight: bold;
      margin-bottom: 0.5rem;
    }
    
    .score-details {
      font-size: 0.875rem;
      color: #6c757d;
    }
    
    .insights {
      .insight-item {
        padding: 0.25rem 0;
        font-size: 0.9rem;
      }
    }
  }
}
```

## Scoring Examples

### Example 1: Boring Same-Key Set
```
Track 1 (8A) → Track 2 (8A) → Track 3 (8A) → Track 4 (8A)
Transitions: Perfect, Perfect, Perfect
Points: 2 + 2 + 2 = 6 out of 9 possible
Score: 67/100

Old Score: 100/100 ❌
New Score: 67/100 ✅ (reflects boring nature)
```

### Example 2: Skilled Variety Set
```
Track 1 (8A) → Track 2 (9A) → Track 3 (9B) → Track 4 (3B)
Transitions: Smooth (+1), Smooth (rel. maj/min), Energy Boost (+7)
Points: 3 + 3 + 3 = 9 out of 9 possible
Score: 100/100

Old Score: 67/100 ❌
New Score: 100/100 ✅ (reflects craft)
```

### Example 3: Mixed Quality Set
```
Track 1 (8A) → Track 2 (9A) → Track 3 (9A) → Track 4 (5B) → Track 5 (6B)
Transitions: Smooth, Perfect, Rough, Smooth
Points: 3 + 2 + 0 + 3 = 8 out of 12 possible
Score: 67/100

Analysis: One rough transition hurts score, suggests reordering Track 4
```

## Migration & Backward Compatibility

### No Database Changes Required
- All scoring is computational
- No data migration needed
- Existing playlists automatically use new scoring

### Potential Breaking Changes
**None** - This is a pure business logic change. Scores will change but:
- No API contracts broken
- No data structure changes
- Users will see different numbers (this is the point!)

### Communication Strategy
When deploying, show users:
```
🎵 Harmonic Scoring Updated!

Your playlist scores may have changed. The new system rewards:
✨ Smooth transitions (±1 key, relative major/minor)
⚡ Intentional energy boosts (+7 positions)
🎯 Musical variety and DJ craft

Same-key transitions are now scored lower because they're safe but less interesting.
```

## Testing Requirements

### Unit Tests

**File:** `test/services/camelot_wheel_service_test.rb`
```ruby
test "transition_score returns 3 for smooth transitions" do
  assert_equal 3, CamelotWheelService.transition_score("8A", "9A")
  assert_equal 3, CamelotWheelService.transition_score("8A", "8B")
end

test "transition_score returns 2 for perfect matches" do
  assert_equal 2, CamelotWheelService.transition_score("8A", "8A")
end

test "transition_score returns 3 for energy boosts" do
  assert_equal 3, CamelotWheelService.transition_score("8A", "3A")
end

test "transition_score returns 0 for rough transitions" do
  assert_equal 0, CamelotWheelService.transition_score("8A", "2B")
end

test "harmonic_flow_score with all smooth transitions" do
  transitions = [
    { from_key: "8A", to_key: "9A" },
    { from_key: "9A", to_key: "10A" },
    { from_key: "10A", to_key: "11A" }
  ]
  assert_equal 100, CamelotWheelService.harmonic_flow_score(transitions)
end

test "harmonic_flow_score with all perfect matches" do
  transitions = [
    { from_key: "8A", to_key: "8A" },
    { from_key: "8A", to_key: "8A" },
    { from_key: "8A", to_key: "8A" }
  ]
  assert_equal 67, CamelotWheelService.harmonic_flow_score(transitions)
end

test "harmonic_flow_score with mixed quality" do
  transitions = [
    { from_key: "8A", to_key: "9A" },  # smooth = 3
    { from_key: "9A", to_key: "9A" },  # perfect = 2
    { from_key: "9A", to_key: "5B" }   # rough = 0
  ]
  # (3 + 2 + 0) / 9 * 100 = 56
  assert_equal 56, CamelotWheelService.harmonic_flow_score(transitions)
end
```

**File:** `test/services/set_analysis_service_test.rb` (if implementing penalties)
```ruby
test "consecutive_penalty applied for 3+ perfect matches in a row" do
  tracks = create_tracks_with_keys(["8A", "8A", "8A", "8A", "8A"])
  service = SetAnalysisService.new(tracks)
  
  # 4 transitions, all perfect = base 67
  # 4 consecutive = (4-2) * 5 = 10 point penalty
  assert_equal 57, service.score
end

test "variety_bonus applied when using 3+ transition types" do
  tracks = create_tracks_with_keys(["8A", "9A", "9B", "3B", "4B"])
  service = SetAnalysisService.new(tracks)
  
  # Uses smooth, energy_boost transitions = variety bonus +10
  assert service.score > service.base_score
end
```

### Integration Tests

**File:** `test/models/playlist_test.rb`
```ruby
test "harmonic_flow_score reflects new scoring system" do
  playlist = create_playlist_with_keys(["8A", "9A", "10A", "11A"])
  # All smooth transitions should score 100
  assert_equal 100, playlist.harmonic_flow_score
end

test "harmonic_analysis provides detailed breakdown" do
  playlist = create_playlist_with_keys(["8A", "8A", "8A", "8A"])
  analysis = playlist.harmonic_analysis
  
  assert analysis[:base_score] < 100
  assert analysis[:insights].any? { |i| i.include?("same-key") }
end
```

## Performance Considerations

### Computation Cost
- **No change** - Same number of calculations as before
- All operations are O(N) where N = number of transitions
- No database queries added
- Penalty/bonus calculations add negligible overhead

### Caching Strategy (Optional)
```ruby
# In Playlist model
def harmonic_flow_score
  Rails.cache.fetch(
    "playlist_#{id}_harmonic_score_v2",
    expires_in: 1.hour
  ) do
    calculate_harmonic_flow_score
  end
end

# Invalidate cache on playlist changes
after_save :clear_harmonic_cache
after_touch :clear_harmonic_cache

private

def clear_harmonic_cache
  Rails.cache.delete("playlist_#{id}_harmonic_score_v2")
end
```

## Documentation Updates

### User-Facing Documentation
Create help tooltip/modal explaining scoring:

```markdown
# Harmonic Flow Score

Your playlist's harmonic flow score (0-100) reflects mixing quality:

**What Gets Rewarded:**
- 🔵 Smooth transitions (±1 key, relative major/minor): +3 points
- ⚡ Energy boosts (+7 positions): +3 points
- 🟢 Perfect matches (same key): +2 points

**What Gets Penalized:**
- 🟡 Rough/incompatible transitions: 0 points
- 3+ consecutive same-key transitions: Small penalty

**Scoring Goal:**
A score of 80+ indicates excellent harmonic mixing with good variety.
70-79 is solid mixing. Below 70 suggests rough transitions or monotony.
```

### Developer Documentation
Add to README or docs/HARMONIC_MIXING.md:

```markdown
## Harmonic Scoring System v2.0

The scoring system rewards DJ craft quality over simple key matching:

- **Smooth transitions**: Highest value (3 points) - requires skill
- **Energy boosts**: High value (3 points) - intentional drama
- **Perfect matches**: Moderate (2 points) - safe but boring
- **Rough transitions**: Zero points - avoid these

See `app/services/camelot_wheel_service.rb` for implementation.
```

## Rollout Plan

### Phase 1: Core Scoring (This Spec)
1. Update `CamelotWheelService.transition_score`
2. Update `CamelotWheelService.harmonic_flow_score`
3. Add tests
4. Update UI labels/tooltips
5. Deploy with release notes

**Estimated Time:** 2-3 hours

### Phase 2: Penalties & Bonuses (Optional)
1. Create `SetAnalysisService`
2. Add `Playlist#harmonic_analysis`
3. Update playlist show page with insights
4. Add tests
5. Deploy

**Estimated Time:** 2-3 hours

## Success Metrics

### Immediate (Post-Deploy)
- ✅ Tests pass with new scoring values
- ✅ Playlist scores recalculate correctly
- ✅ No performance degradation

### Short-term (1-2 weeks)
- 📊 User feedback on score changes
- 📊 Distribution of scores shifts (expect lower average)
- 📊 Users reorder playlists based on insights

### Long-term (1+ month)
- 📊 Higher-quality playlist construction
- 📊 Users understand and trust new scoring
- 📊 Reduced same-key monotony in sets

## Open Questions & Decisions Needed

1. **Should we implement penalty/bonus system immediately or phase 2?**
   - Recommendation: Start simple (phase 1), add later if desired
   
2. **Should we show score history/comparison?**
   - e.g., "Your score changed from 92 → 78 after the update"
   - Recommendation: No, just explain the new system
   
3. **Should rough transitions completely zero out?**
   - Alternative: Give them 0.5 points (very slight credit)
   - Recommendation: Keep at 0 to discourage them
   
4. **Energy boost scoring: Always 3 points?**
   - Alternative: Only high score if positioned in latter 60% of set
   - Recommendation: Keep simple for v2.0, refine later if needed

## Dependencies
- None (uses existing CamelotWheelService)
- No new gems required
- No database changes

## Related Specifications
- Original: `harmonic-mixing-assistant-spec.md`
- Next: `playlist-ordering-optimizer-spec.md` (uses this new scoring)

---

**Ready for Implementation:** ✅
**Reviewed By:** [Pending]
**Implementation Date:** [Pending]
