# Harmonic Mixing Assistant - Feature Specification

**Status:** ✅ Fully Implemented (2025-10-26)

## Overview
Harmonic mixing assistance using Camelot Wheel notation to help find compatible tracks and analyze playlist transitions. This feature is now fully functional in the Music Archive application.

## Key Data Format
- Keys are stored in Camelot notation (e.g., "8A", "8B", "12A")
- All tracks have keys assigned
- Format: `[1-12][A|B]`
  - Number (1-12): Position on Camelot wheel
  - Letter (A/B): A = Minor, B = Major

## Harmonic Compatibility Rules

### Compatible Key Transitions
1. **Perfect Match (Same Key)**
   - 8A → 8A
   - Visual indicator: 🟢 Green

2. **Smooth Transition (Standard Moves)**
   - ±1 position: 8A → 7A or 9A
   - Relative major/minor: 8A ↔ 8B
   - Visual indicator: 🔵 Blue

3. **Energy Boost Jump**
   - +7 positions: 8A → 3A
   - Visual indicator: ⚡ Lightning bolt

4. **Rough/Incompatible**
   - All other transitions
   - Visual indicator: 🟡 Yellow

### BPM Integration
- Optional BPM range filter using slider control
- Default range: ±6 BPM
- Slider range: 0-20 BPM tolerance
- Can be toggled on/off with checkbox

## Use Cases

### Use Case 1: Track Detail - "Find Compatible Tracks"
**Location:** `tracks/show` page

**User Story:** As a DJ, when viewing a track, I want to see all compatible tracks so I can build harmonically smooth playlists.

**UI Elements:**
- Section titled "Compatible Tracks"
- Checkbox: "Filter by BPM range"
- BPM Range Slider: ±0 to ±20 BPM (default: ±6)
  - Shows current value (e.g., "±6 BPM")
  - Only active when checkbox is checked
- Results grouped by compatibility type:
  - **Same Key** (🟢)
  - **Smooth Transitions** (🔵) - includes ±1 and relative major/minor
  - **Energy Boost** (⚡) - +7 positions

**Behavior:**
- Display track count for each category
- Show track details: name, artist, BPM, key
- Click track to navigate to detail page
- Real-time updates when BPM slider changes

### Use Case 2: Playlist Analysis - "Harmonic Flow"
**Location:** `playlists/show` page

**User Story:** As a DJ, when viewing a playlist, I want to see the quality of key transitions between consecutive tracks so I can identify smooth or rough mixes.

**UI Elements:**
- Visual indicators between each track pair showing transition quality
- Overall "Harmonic Flow Score" for entire playlist
  - Calculation: (Perfect × 3 + Smooth × 2 + Energy × 2 + Rough × 0) / (total_transitions × 3) × 100
  - Display as percentage with color coding
- Transition details on hover/click

**Visual Display:**
```
Track 1 (8A)
    🟢 Perfect Match
Track 2 (8A)
    🔵 Smooth Transition
Track 3 (8B)
    ⚡ Energy Boost
Track 4 (3B)
    🟡 Rough Transition
Track 5 (6A)
```

### Use Case 3: Track Index/Search - "Filter by Compatibility"
**Location:** `tracks/index` page

**User Story:** As a DJ, when browsing my library, I want to filter tracks that are compatible with a specific track.

**UI Elements:**
- Dropdown: "Show tracks compatible with:" [Select a track]
  - Searchable dropdown (typeahead)
  - Shows: "Track Name - Artist (Key, BPM)"
- Checkbox: "Filter by BPM range"
- BPM Range Slider: ±0 to ±20 BPM (default: ±6)
- Active filters displayed as dismissible chips/tags
- Results show compatibility badge next to each track

## Dependencies & Libraries

### Backend (Ruby Gems)
**No additional gems required.** After researching existing Ruby gems for Camelot Wheel and harmonic mixing:
- No Camelot-specific gems exist
- General music theory gems (Coltrane, musicraft, musique) are overkill for our simple use case
- Camelot wheel logic is straightforward math (12 positions, 2 modes) - we'll build a custom service

### Frontend (JavaScript Packages)

#### Tom Select (Searchable Dropdown)
```bash
# Add to importmap
./bin/importmap pin tom-select

# Add CSS via yarn
yarn add tom-select
```
- **Purpose:** Searchable dropdown for "Show tracks compatible with" filter
- **Why:** Lightweight, no dependencies, works perfectly with importmap + Stimulus
- **Features:** Typeahead search, keyboard navigation, mobile-friendly
- **Integration:** Import CSS in application.bootstrap.scss
- **Docs:** https://tom-select.js.org/

#### Native HTML5 Range Input (BPM Slider)
**No package needed** - Using native `<input type="range">` with Bootstrap 5 styling
- **Why:** Already available, Bootstrap 5.3.3 includes excellent range input styling
- **Features:** Responsive, accessible, no extra dependencies
- **Customization:** Stimulus controller for real-time value display and state management

## Implementation Components

### 1. Backend Services

#### `CamelotWheelService` (`app/services/camelot_wheel_service.rb`)
```ruby
# Responsibilities:
# - Parse Camelot notation (e.g., "8A" → {position: 8, mode: 'A'})
# - Calculate compatible keys based on rules
# - Rate transition quality between two keys
# - Return compatibility type: :perfect, :smooth, :energy_boost, :rough

class CamelotWheelService
  POSITIONS = (1..12).to_a
  MODES = ['A', 'B']

  def self.parse_key(key_name)
  def self.compatible_keys(key_name, level: :all)
  def self.transition_quality(from_key, to_key)
  def self.harmonic_flow_score(transitions_array)
end
```

#### `HarmonicMixingService` (`app/services/harmonic_mixing_service.rb`)
```ruby
# Responsibilities:
# - Find compatible tracks for a given track
# - Apply BPM range filtering
# - Analyze playlist transitions

class HarmonicMixingService
  def initialize(track, bpm_range: nil)
  def find_compatible_tracks
  def self.analyze_playlist_transitions(playlist)
end
```

### 2. Model Enhancements

#### `Key` model
```ruby
# Add methods:
def compatible_keys(level: :all)
  # Returns Key objects that are compatible
  # level: :same, :smooth, :energy_boost, :all
end

def transition_quality_to(other_key)
  # Returns: :perfect, :smooth, :energy_boost, :rough
end
```

#### `Track` model
```ruby
# Add methods:
def find_compatible(bpm_range: nil)
  # Returns hash grouped by compatibility type
  # { perfect: [...], smooth: [...], energy_boost: [...] }
end

def compatible_with?(other_track, bpm_range: nil)
  # Boolean check
end
```

#### `Playlist` model
```ruby
# Add methods:
def analyze_transitions
  # Returns array of transition objects
  # [{ from: Track, to: Track, quality: :smooth, indicator: '🔵' }, ...]
end

def harmonic_flow_score
  # Returns 0-100 score
end
```

### 3. Controllers

#### `TracksController`
```ruby
# Add action:
def compatible
  # Returns JSON for AJAX requests
  # Params: track_id, bpm_range (optional)
end
```

#### `PlaylistsController`
```ruby
# Enhance show action:
# - Include transition analysis data
# - Pass to view for rendering
```

### 4. Frontend Components

#### Stimulus Controllers
- `harmonic-filter-controller.js` - Handle BPM slider + checkbox logic
- `transition-indicator-controller.js` - Interactive transition details on hover

#### Views to Modify
- `app/views/tracks/show.html.erb` - Add compatible tracks section
- `app/views/tracks/index.html.erb` - Add compatibility filter
- `app/views/playlists/show.html.erb` - Add transition indicators

#### CSS Classes
- `.transition-indicator` - Emoji/icon styling
- `.harmonic-flow-score` - Score badge with color coding
- `.compatibility-badge` - Track compatibility type badge
- `.bpm-slider-container` - Slider control styling

## Database Impact
- **No schema changes required** - Uses existing Key and Track relationships
- All logic is computational, no new tables needed

## Testing Considerations
- Test Camelot wheel calculations for all 12 positions × 2 modes
- Verify +7 energy boost wraps correctly (12A + 7 = 7A)
- Test BPM range filtering edge cases
- Validate transition quality calculations
- Test harmonic flow score calculation

## Future Enhancements (Out of Scope)
- "Auto-sort playlist by harmonic flow" feature
- Key change suggestions for improved transitions
- Export playlist analysis as PDF/report
- Integration with Rekordbox import to suggest track order

---

**Created:** 2025-10-26
**Implemented:** 2025-10-26
**Status:** ✅ Complete

## Implementation Notes

### Completed Features
All planned features have been successfully implemented:

✅ **Backend Services**
- `CamelotWheelService` - Full Camelot wheel logic with all transition types
- `HarmonicMixingService` - Track compatibility and playlist analysis
- All model methods (`Key`, `Track`, `Playlist`)

✅ **Frontend Components**
- Track detail page with compatible tracks section
- Playlist detail page with transition indicators and harmonic flow score
- Playlist index with harmonic score badges on cards
- Tracks index with compatibility filter

✅ **UI Enhancements**
- BPM slider (±0-20 BPM) with show/hide toggle
- Tom Select searchable dropdown for track selection
- Color-coded badges (green/yellow/red) for scores
- Visual transition indicators between playlist tracks

### Implementation Differences from Original Spec

**Dependencies**
- **Bootstrap JS**: Not implemented - using native HTML5 tooltips instead of Bootstrap tooltips
- **Tom Select**: Loaded via CDN (`<script>` tag) instead of importmap due to module resolution issues
- **BPM Slider**: Using native HTML5 `<input type="range">` with Bootstrap 5 styling (no external package needed)

**SQL Compatibility**
- Fixed SQL reserved word issue: `playlists_tracks.order` → `playlists_tracks."order"` (quoted for SQLite)

**UI Adjustments**
- Added info alert on tracks index explaining pagination limitation (client-side filtering)
- Harmonic score badges positioned at top-center of playlist cards (instead of separate section)
- BPM slider visibility controlled via JavaScript (hidden by default)
- Bootstrap icon fonts copied to `public/fonts/` for proper serving

### File Locations

**Backend**
- `app/services/camelot_wheel_service.rb`
- `app/services/harmonic_mixing_service.rb`
- `app/models/key.rb` (enhanced)
- `app/models/track.rb` (enhanced)
- `app/models/playlist.rb` (enhanced)

**Controllers**
- `app/controllers/tracks_controller.rb` (added `show` and `compatible` actions)
- `app/controllers/playlists_controller.rb` (enhanced `show` action)

**Views**
- `app/views/tracks/show.html.erb` (new)
- `app/views/tracks/index.html.erb` (enhanced)
- `app/views/playlists/show.html.erb` (enhanced)
- `app/views/playlists/index.html.erb` (enhanced)

**JavaScript**
- `app/javascript/controllers/harmonic_filter_controller.js`
- `app/javascript/controllers/transition_indicator_controller.js`

**Styles**
- `app/assets/stylesheets/application.bootstrap.scss` (added harmonic mixing styles)

**Routes**
- Added: `GET /tracks/:id` (show)
- Added: `GET /tracks/:id/compatible` (AJAX endpoint)

### Performance Considerations
- Harmonic analysis is computed on-demand (not cached)
- Compatible track queries use proper indexes (key_id, bpm)
- Client-side filtering on tracks index to avoid pagination complexity
- All Camelot calculations are pure Ruby (no database queries)

### Testing Results
✅ Camelot wheel calculations verified for all transition types
✅ Compatible track finding working (example: 51 perfect, 40 smooth, 26 energy boost)
✅ Playlist analysis computing scores correctly
✅ UI interactions (sliders, dropdowns, filters) working smoothly

### Known Limitations
1. **Tracks Index Filtering**: Only filters visible tracks on current page (not full database)
   - Workaround documented in UI with info alert
   - For full filtering, users should use the Track Detail page
2. **Tooltips**: Using browser native tooltips instead of Bootstrap fancy tooltips
   - Still functional, just less visually polished
3. **Performance**: Harmonic score calculation runs on every playlist page load
   - Consider caching for large playlists if performance becomes an issue
