# Harmonic Mixing & Playlist Optimization Specifications

## 📁 Files in This Package

### 1. [harmonic-scoring-system-spec.md](harmonic-scoring-system-spec.md) (17KB)
**Priority:** HIGH - Must implement first
**Effort:** 4-6 hours

Revised scoring system that rewards DJ craft quality over safe same-key mixing.

**Key Changes:**
- Smooth transitions (±1, relative major/minor): **3 points** 
- Energy boosts (+7): **3 points**
- Perfect matches (same key): **2 points** (reduced from highest)
- Optional penalty system for consecutive same-key transitions

**Why First:** The playlist optimizer depends on this scoring system.

---

### 2. [playlist-ordering-optimizer-spec.md](playlist-ordering-optimizer-spec.md) (41KB)
**Priority:** MEDIUM - Implement after scoring system
**Effort:** 12-20 hours

Automatic playlist ordering using multiple algorithms based on size.

**Algorithms:**
- **2-10 tracks:** Brute force (optimal, 1-3 sec)
- **11-15 tracks:** Branch & bound (near-optimal, 5-30 sec)  
- **16-25 tracks:** Genetic algorithm (very good, 10-30 sec)
- **26+ tracks:** Greedy with lookahead (decent, instant)

**Features:**
- Harmonic flow optimization (uses scoring system v2.0)
- Energy arc consideration (BPM + Key mode)
- Optional constraints (start/end with specific tracks)
- Configurable weights (harmonic vs. energy)

---

### 3. [ENERGY_ARC_SUMMARY.md](ENERGY_ARC_SUMMARY.md) (5KB)
**Type:** Reference document

Quick reference for the energy arc implementation approach.

**Key Points:**
- Uses existing data (BPM + Key mode)
- No new database fields required
- 80% from BPM, 20% from major/minor key
- Simple, fast, deterministic calculation

---

## 🎯 Implementation Order

### Session 1: Harmonic Scoring System v2.0
**File:** `harmonic-scoring-system-spec.md`
**Time:** 4-6 hours

1. Update `CamelotWheelService.transition_score` (30 min)
2. Update `CamelotWheelService.harmonic_flow_score` (30 min)
3. Create `SetAnalysisService` (optional penalties) (1-2 hours)
4. Update `Playlist#harmonic_flow_score` (30 min)
5. Update UI labels and tooltips (30 min)
6. Write tests (1-2 hours)
7. Deploy with release notes (30 min)

**Deliverables:**
- ✅ New scoring system live
- ✅ Playlists automatically recalculate with new scores
- ✅ Users understand scoring changes

---

### Session 2: Playlist Ordering Optimizer
**File:** `playlist-ordering-optimizer-spec.md`
**Time:** 12-20 hours

#### Phase 1: Core Optimizer (8-12 hours)
1. Create `PlaylistOptimizerService` (2-3 hours)
   - Brute force algorithm
   - Genetic algorithm
   - Energy arc scoring
2. Update `Playlist` model (1 hour)
3. Add controller actions (1-2 hours)
4. Basic UI (button + results) (2-3 hours)
5. Core tests (2-3 hours)

#### Phase 2: Polish (4-8 hours)
1. Branch & bound algorithm (2-3 hours)
2. Optimization options modal (1-2 hours)
3. Progress indicators (1 hour)
4. Revert functionality (1 hour)
5. Comprehensive testing (1-2 hours)

**Deliverables:**
- ✅ Working optimizer for playlists up to 25 tracks
- ✅ Energy arc + harmonic flow combined
- ✅ User-configurable weights
- ✅ One-click optimization

---

## 🔑 Key Decisions Made

### Energy Arc Approach: BPM + Key Mode ✅
**Decision:** Use simple formula with existing data
```ruby
energy = (bpm_normalized * 0.8) + (major_key_bonus * 0.2)
```

**Rationale:**
- ✅ No new database fields
- ✅ 80% accurate for electronic music
- ✅ Simple and fast
- ✅ Users can disable if desired

**Alternative Rejected:** Manual energy tagging (too much user input required)

---

### Default Scoring Weights ✅
**Decision:** 70% harmonic, 30% energy (configurable)

**Rationale:**
- Harmonic compatibility is primary concern
- Energy arc adds professional polish
- Users can adjust or disable

---

### Algorithm Selection Strategy ✅
**Decision:** Auto-select based on playlist size (hidden from user)

**Rationale:**
- Simpler UX (no technical choices)
- Always optimal performance
- Can expose later if power users request it

---

## 📊 What Data Is Required

### Already Have (No Changes Needed)
| Field | Model | Used For |
|-------|-------|----------|
| `bpm` | Track | Energy estimation (80%) |
| `key.name` | Key | Harmonic compatibility + Energy bonus (20%) |
| `order` | PlaylistTrack | Current/result order |

### NOT Required
- ❌ No `energy_level` field
- ❌ No `genre` field  
- ❌ No new tables
- ❌ No migrations

**Zero database changes!** ✅

---

## 🧪 Testing Strategy

### Scoring System Tests
- [ ] Transition score values (2 vs 3 points)
- [ ] Harmonic flow score calculation
- [ ] Consecutive penalty system (if implemented)
- [ ] Variety bonus (if implemented)

### Optimizer Tests
- [ ] Brute force finds optimal (8-10 tracks)
- [ ] Genetic completes in time (20-25 tracks)
- [ ] Energy arc scoring accuracy
- [ ] Combined scoring with different weights
- [ ] Start/end constraints respected
- [ ] Revert functionality

### Performance Benchmarks
| Tracks | Algorithm | Target Time |
|--------|-----------|-------------|
| 5 | Brute force | < 1 sec |
| 10 | Brute force | < 3 sec |
| 15 | Branch & bound | < 30 sec |
| 20 | Genetic | < 30 sec |
| 25 | Genetic | < 60 sec |

---

## ⚠️ Important Notes

### Prerequisites
1. **MUST** complete Harmonic Scoring System v2.0 first
2. Optimizer depends on new scoring logic
3. Both specs use only existing data (no migrations)

### Optional Enhancements (Future)
- Background job processing (16+ tracks)
- ActionCable progress updates
- Manual track locking (pin specific positions)
- Export optimization reports
- A/B comparison view
- Manual energy level tags

### Limits & Warnings
- Hard limit: 50 tracks max (configurable)
- Soft warning: 25+ tracks (may take 1-2 min)
- Genetic algorithm results vary slightly between runs
- Energy arc estimation ~80% accurate (good enough!)

---

## 📈 Success Metrics

### Immediate (Post-Deploy)
- ✅ All tests pass
- ✅ No performance degradation
- ✅ Users can optimize playlists

### Short-term (1-2 weeks)
- 📊 % of playlists optimized
- 📊 Average score improvement
- 📊 Computation times meet targets
- 📊 User feedback on results

### Long-term (1+ month)
- 📊 Do users keep optimized orderings?
- 📊 How often do users re-optimize?
- 📊 Correlation with user engagement

---

## 🚀 Quick Start

### For Session 1 (Scoring)
```bash
# Read the spec
open harmonic-scoring-system-spec.md

# Key files to modify
app/services/camelot_wheel_service.rb
app/services/set_analysis_service.rb  # Optional penalties
app/models/playlist.rb
app/views/playlists/show.html.erb
```

### For Session 2 (Optimizer)
```bash
# Read the spec
open playlist-ordering-optimizer-spec.md

# Also read energy arc summary
open ENERGY_ARC_SUMMARY.md

# Key files to create
app/services/playlist_optimizer_service.rb
app/controllers/playlists_controller.rb  # Add optimize action
app/views/playlists/show.html.erb        # Add optimize button
```

---

## 💡 Pro Tips

1. **Start Simple:** Implement core algorithms first, add polish later
2. **Test Early:** Write tests as you go, not at the end
3. **Use Benchmarks:** Profile actual performance vs. specs
4. **Get Feedback:** Deploy scoring system, get user reactions before optimizer
5. **Iterate:** Don't try to implement all features in first pass

---

## 📞 Questions While Implementing?

The specs include:
- ✅ Detailed code examples in Ruby
- ✅ Complete algorithm implementations
- ✅ UI mockups and workflows
- ✅ Testing strategies
- ✅ Performance benchmarks
- ✅ Open questions with recommendations

If you encounter edge cases not covered, document them and make pragmatic decisions based on:
1. User experience (keep it simple)
2. Performance (stay within time targets)
3. Code maintainability (avoid premature optimization)

---

**Created:** 2025-11-07
**Total Pages:** 63 pages (17KB + 41KB + 5KB)
**Estimated Total Implementation Time:** 16-26 hours
**Ready to Start:** ✅ Yes!

Good luck with the implementation! 🎵🎧
