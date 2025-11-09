# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.1 music archive application for managing DJ playlists. It allows importing playlists from tab-delimited files, managing tracks with metadata (BPM, key, artists), and organizing music collections.

Ruby version: 3.3.10
Rails version: 8.1.0

## Typical Usage Workflow

This application is designed for **retrospective playlist analysis** - analyzing DJ sets after they've been played to learn from harmonic mixing decisions and build a searchable music archive.

### The Workflow
1. **Create a playlist in Rekordbox** - Mix tracks during a DJ set or while preparing a performance
2. **Export from Rekordbox** - Export the playlist as a tab-delimited text file
3. **Import into the app** - Upload the exported file to build the music archive incrementally
4. **Analyze harmonic transitions** - Review how well tracks flowed together using the harmonic mixing assistant
5. **Discover patterns** - Learn which key and BPM combinations work well for future sets
6. **Maintain unique tracks** - The archive focuses on unique tracks across playlists, avoiding duplicates to encourage exploration of new music

### Key Principles
- **Retrospective analysis**: The app is not for planning future mixes, but for learning from past ones
- **Unique track collection**: Each playlist should contain unique tracks not yet in the archive, maximizing the diversity of the music library
- **Learning tool**: The harmonic mixing scores and compatibility filters help identify successful transitions and discover why certain tracks worked well together
- **Growing archive**: As more playlists are imported, the searchable archive grows, making it easier to find tracks for future sets

## Development Commands

### Server and Development
```bash
# Start development server and CSS watcher
bin/dev

# Start Rails server only
bin/rails server

# Rails console
bin/rails console
```

### Database
```bash
# Create database
bin/rails db:create

# Run migrations
bin/rails db:migrate

# Rollback last migration
bin/rails db:rollback

# Reset database (drop, create, migrate)
bin/rails db:reset

# Load schema
bin/rails db:schema:load
```

### Asset Pipeline
```bash
# Build CSS (compile SASS + autoprefixer)
yarn build:css

# Watch and rebuild CSS on changes
yarn watch:css

# Compile SASS only
yarn build:css:compile

# Run autoprefixer only
yarn build:css:prefix
```

### Dependencies
```bash
# Install Ruby gems
bundle install

# Install Node packages
yarn install
```

### Continuous Integration
```bash
# Run full CI suite (recommended before commits)
bin/ci

# This runs:
# - bin/setup --skip-server (dependency check)
# - bin/importmap audit (security vulnerabilities)
# - bundle exec rubocop (code quality)
# - bundle exec rspec (test suite)
# - env RAILS_ENV=test bin/rails db:seed:replant (seed verification)
```

## Development Workflow

When implementing features, fixes, or improvements, follow this workflow to ensure code quality and maintainability:

### 1. Implement the Feature/Fix
- Make code changes to implement the requested functionality
- Follow existing code patterns and conventions
- Update relevant documentation files (CLAUDE.md, HARMONIC_MIXING_SPEC.md, etc.)

### 2. Add/Modify/Optimize Tests
- **Always** add test coverage for new features
- Modify existing tests if behavior changed
- Optimize test suite for clarity and maintainability
- Aim for high code coverage (target: >85%)

```bash
# Run specific test file
bundle exec rspec spec/path/to/spec.rb

# Run all tests
bundle exec rspec
```

### 3. Run Full CI Suite
Before considering the work complete, **always run the full CI suite**:

```bash
bin/ci
```

This ensures:
- ✅ All tests pass
- ✅ Code style is compliant (RuboCop)
- ✅ No security vulnerabilities
- ✅ Database seeds work correctly

### 4. Prepare for Commit
Once `bin/ci` passes successfully, the code is ready for committing. Use **conventional commit messages**:

#### Commit Message Format
```
<type>: <description>

[optional body]

[optional footer]
```

#### Commit Types
- `feat:` - New feature (e.g., "feat: add server-side compatibility filtering")
- `fix:` - Bug fix (e.g., "fix: resolve search query for tracks without playlists")
- `chore:` - Maintenance tasks (e.g., "chore: update dependencies")
- `docs:` - Documentation only (e.g., "docs: update CLAUDE.md with workflow guidelines")
- `style:` - Code style changes (e.g., "style: fix RuboCop offenses")
- `refactor:` - Code refactoring without behavior change
- `test:` - Adding or updating tests
- `perf:` - Performance improvements

#### Examples
```bash
git add .
git commit -m "feat: implement server-side harmonic compatibility filtering

- Add compatibility filtering to TracksController#index
- Support BPM range toggle with enable_bpm_filter param
- Preserve filter parameters across pagination and sorting
- Add 8 comprehensive test cases (87.78% coverage)
- Update CLAUDE.md and HARMONIC_MIXING_SPEC.md"

git commit -m "fix: use LEFT OUTER JOINs in Track.search for better coverage"

git commit -m "test: add comprehensive specs for compatibility filtering"

git commit -m "docs: document retrospective usage workflow in CLAUDE.md"
```

### 5. Code Quality Guidelines

**IMPORTANT: Never disable RuboCop cops unless absolutely necessary**

When RuboCop reports an offense:
1. **First, fix the underlying issue** - Refactor code to comply with the cop
2. **Consider if the cop is correct** - RuboCop usually catches real code quality issues
3. **Only disable as a last resort** - If there's truly no other solution, document why

Common patterns to use instead of disabling cops:
- **Instead of case with duplicate branches** → Use hash lookup with constants
- **Instead of complex conditionals** → Extract methods or use guard clauses
- **Instead of long methods** → Break into smaller, focused methods

Example:
```ruby
# ❌ Bad: Disabling cops
# rubocop:disable Style/HashLikeCase
case quality
when :smooth then 3
when :energy_boost then 3
when :perfect then 2
end
# rubocop:enable Style/HashLikeCase

# ✅ Good: Fix the issue with constants
SCORES = { smooth: 3, energy_boost: 3, perfect: 2 }.freeze
SCORES[quality]
```

### 6. Code Review Checklist
Before committing, verify:
- [ ] Feature/fix works as expected
- [ ] Tests added and passing (bin/ci ✅)
- [ ] RuboCop compliant (no cops disabled unnecessarily)
- [ ] Documentation updated (CLAUDE.md, specs, comments)
- [ ] No security vulnerabilities
- [ ] Conventional commit message prepared

## Architecture

### Core Data Models

**Playlist** - Container for ordered tracks (imported from Rekordbox exports)
- Has many tracks through `playlists_tracks` join table
- Uses ActiveStorage for cover art attachments
- Auto-attaches default cover art on creation (`app/assets/images/default_cover_art.jpg`)
- Has `unique_identifier` method that creates track order signature for duplicate detection
- Read-only after creation (retrospective analysis focus)

**DjSet** - Manually curated track collections for planning future mixes
- Has many tracks through `dj_sets_tracks` join table
- Fully editable: add, remove, reorder tracks
- Unique name validation (case-insensitive, max 100 chars)
- Optional description (max 500 chars)
- Supports harmonic flow analysis like Playlists
- Can be duplicated, exported to file, or converted to Playlist
- Methods: `ordered_tracks`, `harmonic_flow_score`, `harmonic_analysis`, `duplicate`, `export_to_file`, `convert_to_playlist`

**DjSetsTrack** - Join table between DjSets and Tracks
- Stores track order within set via `order` column
- Primary key: auto-incrementing id
- Uniqueness validation: prevents duplicate tracks in same set
- Automatically resequenced after add/remove operations to maintain sequential order (1, 2, 3...)
- Can be reordered via `dj_sets#reorder_tracks` endpoint (drag-and-drop UI)

**Track** - Individual music track (permanent library)
- Belongs to optional Key (musical key like "A Major", "C# Minor")
- Has many playlists through `playlists_tracks`
- Has many dj_sets through `dj_sets_tracks`
- Has and belongs to many Artists (HABTM relationship via `artists_tracks`)
- Uses ActiveStorage for audio file attachments
- Fields: name, bpm (decimal), time (in seconds), album, date_added
- Includes `search` class method for full-text search across track name, artist, key, BPM, playlist, and DJ set
  - Uses LEFT OUTER JOINs to include tracks even without associated playlists, keys, artists, or DJ sets
- **Tracks are permanent**: Once imported, tracks remain in database even if removed from all playlists/sets
  - This allows experimentation with different set configurations using the Set Builder feature
  - Tracks can be reused across multiple playlists and DJ sets

**PlaylistsTrack** - Join table between Playlists and Tracks
- Stores track order within playlist via `order` column
- Primary key: auto-incrementing id
- Can be reordered via `playlists#reorder_tracks` endpoint

**Artist** - Music artist/performer
- Has and belongs to many tracks
- Has `before_destroy` callback to prevent deletion if tracks exist
- Names are stored once and reused across tracks

**Key** - Musical key reference table
- Unique constraint on name
- Optional relationship with tracks

### Track Import System

The import system uses a class hierarchy to share common file parsing logic between Playlists and DJ Sets.

**TrackImporter** (`app/services/track_importer.rb`) - Base class
- Shared file parsing logic for all importers
- Required headers: `#`, `Track Title`, `Artist`, `BPM`, `Date Added`
- Optional headers: `Key`, `Time`, `Album`
- Handles flexible column ordering (headers can be in any order)
- Uses rchardet (pure Ruby) for encoding detection (handles non-UTF-8 files)
- Processes BOM (Byte Order Mark) removal
- Creates/finds tracks, artists, and keys during import
- Multiple artists per track supported (comma-separated in file)

**PlaylistImporter** (`app/services/playlist_importer.rb`) - Inherits from TrackImporter
- Creates playlists from tab-delimited files (e.g., Rekordbox exports)
- Validates duplicate playlists by comparing track IDs (prevents importing same playlist twice)
- Wrapped in database transaction for atomicity
- Read-only after creation (retrospective analysis focus)

**DjSetImporter** (`app/services/dj_set_importer.rb`) - Inherits from TrackImporter
- Imports tracks into DJ Sets from tab-delimited files
- Can create new sets OR append tracks to existing sets
- No duplicate detection (allows importing similar track lists into different sets)
- Automatically resequences tracks after import to ensure sequential order (1, 2, 3...)
- Skips tracks that already exist in the target set
- Wrapped in database transaction for atomicity

### Controller Responsibilities

**PlaylistsController**
- Import: Creates playlist from uploaded file, extracts name from filename
- Show/Index: Display playlists with harmonic analysis
- Destroy: Deletes playlist only (tracks and artists remain in database as permanent library)
- Reorder: Updates track order via AJAX (uses `update_column` for performance)

**DjSetsController**
- Full CRUD operations for DJ sets
- **Create with Import**: Create new set from file upload (extracts name from filename)
- **Import Tracks**: Append tracks to existing set from file upload (`/dj_sets/:id/import_tracks`)
- Add Tracks: Adds multiple tracks to set with sequential ordering (from Set Builder)
- Remove Track(s): Single or bulk removal with automatic resequencing
- Reorder: Drag-and-drop track reordering via AJAX (returns updated harmonic score)
- Duplicate: Creates copy of set with new name
- Export: Downloads set as tab-delimited file (compatible with both importers)
- Convert to Playlist: Transforms set into a playlist, optionally deleting original
- **Optimize** (`POST /dj_sets/:id/optimize`): Optimizes track order using PlaylistOptimizerService
  - Accepts params: `start_track_id`, `end_track_id`, `harmonic_weight`, `energy_weight`
  - Stores pre-optimization order in session for revert capability
  - Redirects with success message showing score improvement, method used, and computation time
- **Revert Optimization** (`PATCH /dj_sets/:id/revert_optimization`): Restores original track order from session

**TracksController**
- Index with search functionality (full-text across database including DJ sets)
- Shows both Playlists and DJ Sets columns for each track
- Server-side harmonic compatibility filtering with optional BPM range
- Individual track display (shows associated playlists and DJ sets)
- Audio file upload endpoint
- AJAX endpoint for compatible tracks (`/tracks/:id/compatible`)
- **Set Builder Integration**: Multi-select UI with sessionStorage persistence across pagination
- Eager loads associations (`:artists, :key, :playlists, :dj_sets`) to avoid N+1 queries

**ArtistsController & KeysController**
- Index and show views for browsing

### Harmonic Mixing System

**Overview**
The harmonic mixing feature helps DJs find compatible tracks and analyze playlist transitions using Camelot Wheel notation. All tracks have keys stored in Camelot format (e.g., "8A", "12B").

**Scoring System v2.0** (Updated: 2025-11-09)
The scoring system rewards **DJ craft quality** and **musical variety** over simple key matching:
- **Smooth transitions** (±1 position or relative major/minor): **3 points** - Shows skill + variety
- **Energy boosts** (+7 positions): **3 points** - Intentional energy management for peaks
- **Perfect matches** (same key): **2 points** - Safe but musically less interesting
- **Rough transitions** (incompatible): **0 points** - Should be avoided

This encourages DJs to create dynamic, engaging sets rather than boring same-key sequences.

**CamelotWheelService** (`app/services/camelot_wheel_service.rb`)
- Parses Camelot notation: Format `[1-12][A|B]` where number = wheel position, letter = mode (A=Minor, B=Major)
- Calculates compatible keys based on harmonic mixing rules:
  - **Perfect**: Same key (8A → 8A)
  - **Smooth**: ±1 position (8A → 7A, 9A) or relative major/minor (8A ↔ 8B)
  - **Energy Boost**: +7 positions forward (8A → 3A)
  - **Rough**: All other transitions
- `transition_score(from_key, to_key)` - Returns numeric score for a single transition (0-3 points)
- `harmonic_flow_score(transitions)` - Computes overall score (0-100%) for playlists/sets
- **Formula v2.0**: `(Smooth × 3 + Energy × 3 + Perfect × 2 + Rough × 0) / (total_transitions × 3) × 100`

**SetAnalysisService** (`app/services/set_analysis_service.rb`)
- Provides detailed harmonic analysis with penalties and bonuses
- **Consecutive Penalty**: Penalizes 3+ consecutive same-key transitions (max -30 points)
  - Formula: `(consecutive_count - 2) × 5` points per run
- **Variety Bonus**: Rewards using diverse transition types
  - 3-4 different types: +10 points
  - 2 types: +5 points
- Generates insights and recommendations for improving set flow
- Methods: `score`, `detailed_analysis`, `generate_insights`, `transition_breakdown`

**PlaylistOptimizerService** (`app/services/playlist_optimizer_service.rb`)
- Automatically optimizes DJ Set track order for better harmonic flow and energy arc
- Works with both Playlist and DjSet models (polymorphic design via duck typing)
- **Algorithm Selection** (based on track count):
  - 2-10 tracks: **Brute Force** - Guaranteed optimal solution (tries all permutations)
  - 11-25 tracks: **Genetic Algorithm** - 85-95% optimal with configurable generations/population
  - 26-50 tracks: **Greedy with Lookahead** - 70-85% optimal, fast for large sets
- **Energy Estimation**: Estimates track energy from BPM (80%) and key mode (20%)
  - BPM range: 80-160 for electronic music
  - Major keys (B) get +20 brightness bonus
- **Ideal Energy Curve**: Generates target energy progression:
  - Opening (0-10%): Ease in at mid-energy (40 → 50)
  - Build (10-60%): Steady climb (50 → 100)
  - Peak (60-70%): Maximum energy (100)
  - Drop (70-90%): Cool down (100 → 50)
  - Closing (90-100%): Wind down (50 → 10)
- **Combined Scoring**: Balances harmonic flow (default 70%) with energy arc (default 30%)
  - Uses SetAnalysisService for harmonic scoring
  - Uses Mean Squared Error for energy arc matching
- **Constraints**: Supports optional start/end track locking
- **Result Metadata**: Returns old score, new score, improvement %, computation time, method used
- Methods: `optimize!`, `apply_optimization!`, `score_arrangement`, `energy_arc_score`
- Limits: 2-50 tracks only
- **Note**: Currently used for DJ Set optimization. Playlists are read-only historical records.

**HarmonicMixingService** (`app/services/harmonic_mixing_service.rb`)
- Finds compatible tracks for a given track with optional BPM range filtering
- Analyzes playlist transitions returning quality metrics and indicators
- Groups results by compatibility type (perfect, smooth, energy_boost)

**Model Methods**
- `Key#compatible_keys(level:)` - Returns compatible Key records
- `Key#transition_quality_to(other_key)` - Rates transition quality
- `Track#find_compatible(bpm_range:)` - Finds compatible tracks with optional BPM filter
- `Track#compatible_with?(other_track, bpm_range:)` - Boolean compatibility check
- `Playlist#analyze_transitions` - Returns array of transition objects
- `Playlist#harmonic_flow_score` - Returns 0-100 score (uses v2.0 scoring)
- `Playlist#harmonic_analysis` - Full analysis with stats
- `Playlist#detailed_harmonic_analysis` - **v2.0**: Detailed analysis with penalties, bonuses, and insights
- `Playlist#tracks_in_order` - Returns ordered tracks array
- `DjSet#analyze_transitions` - Same as Playlist
- `DjSet#harmonic_flow_score` - Returns 0-100 score (uses v2.0 scoring)
- `DjSet#harmonic_analysis` - Full analysis with stats
- `DjSet#detailed_harmonic_analysis` - **v2.0**: Detailed analysis with penalties, bonuses, and insights
- `DjSet#tracks_in_order` - Returns ordered tracks array
- `DjSet#optimize_order!(options)` - Optimizes track order using PlaylistOptimizerService
  - Options: `harmonic_weight`, `energy_weight`, `start_with`, `end_with`, `generations`, `population_size`, `mutation_rate`, `lookahead`
  - Returns optimization result hash with scores and metadata
- `DjSet#duplicate(new_name:)` - Creates copy of set
- `DjSet#export_to_file` - Exports as tab-delimited text
- `DjSet#convert_to_playlist(name:, cover_art:, description:)` - Converts to Playlist

**UI Features**
1. **Track Detail Page** (`tracks/show`): "Compatible Tracks" section with BPM slider (±0-20 BPM), results grouped by compatibility type (AJAX loading)
2. **Playlist Detail Page** (`playlists/show`):
   - Harmonic flow score badge with v2.0 breakdown (penalties, bonuses, insights)
   - Transition quality indicators between tracks
3. **Playlist Index** (`playlists/index`): Color-coded harmonic score badges on cards (green ≥75%, yellow ≥50%, red <50%)
4. **Tracks Index** (`tracks/index`): Server-side compatibility filter with BPM range that works across entire database, supports pagination and sorting
5. **DJ Sets Index** (`dj_sets/index`): List of all sets with track count, BPM average, duration, harmonic score badges
6. **DJ Set Detail** (`dj_sets/show`):
   - Full track listing with drag-and-drop reordering
   - Bulk track removal
   - Harmonic analysis with v2.0 breakdown (penalties, bonuses, insights)
   - Transition quality indicators between tracks
   - **DJ Set Optimizer** (collapsible section):
     - Start/End track dropdowns (optional constraints)
     - Harmonic/Energy weight slider (0-100%)
     - Algorithm info tooltip (shows which algorithm will be used based on track count)
     - "Optimize Set" button
     - "Revert to Original Order" button (appears after optimization)

**Set Builder Feature** (See [SET_BUILDER_SPEC.md](SET_BUILDER_SPEC.md) for full specification)
- **Track Selection UI**: Multi-select checkboxes on tracks index page
- **Persistence**: Uses sessionStorage to maintain selections across pagination/filtering
- **Select All**: Header checkbox with indeterminate state support
- **Bottom Toolbar**: Fixed toolbar showing selection count and action buttons (appears when tracks selected)
- **Modal Dialog**: Choose existing set or create new set with name/description
- **Add Tracks**: POST to `/dj_sets/:id/add_tracks` with automatic ordering
- **Bulk Removal**: Multi-select with confirmation dialog, automatic resequencing
- **Drag-and-Drop Reordering**: SortableJS integration with real-time harmonic score updates

**Stimulus Controllers**
- `harmonic_filter_controller.js` - Handles BPM slider, checkbox toggle, track filtering, Tom Select dropdown
- `transition_indicator_controller.js` - Adds native browser tooltips to transition indicators using HTML `title` attribute (not Bootstrap tooltips - simpler, no dependencies)
- `set_builder_controller.js` - Manages track selection, sessionStorage persistence, toolbar visibility, modal interactions
- `sortable_controller.js` - Drag-and-drop track reordering for DJ sets (uses SortableJS library)
- `track_remover_controller.js` - Bulk track removal with select all/none functionality
- `optimizer_controller.js` - Manages DJ Set optimizer UI (collapsible section toggle, harmonic/energy weight slider updates)

### File Organization

- `app/services/` - Business logic (PlaylistImporter, CamelotWheelService, HarmonicMixingService, SetAnalysisService, PlaylistOptimizerService)
- `app/models/concerns/` - Shared model mixins
- `app/assets/stylesheets/` - SCSS files (Bootstrap-based)
- `app/assets/builds/` - Compiled CSS output
- Database uses SQLite3 in all environments

## Important Implementation Details

### Character Encoding
The track import system handles various character encodings using the `rchardet` gem (pure Ruby, no native extensions). Files are detected for encoding and converted to UTF-8 with replacement characters for invalid sequences.

### Permanent Library Approach
**Tracks and artists are never automatically deleted.** Once imported, they remain in the database as a permanent library, even if removed from all playlists and DJ sets. This design decision supports:
- **Set Builder experimentation**: Users can freely add/remove tracks from sets without losing them
- **Track reusability**: Same track can exist in multiple playlists and DJ sets
- **Music discovery**: Build up a searchable library over time
- **Data preservation**: No accidental data loss when deleting playlists/sets

Users can manually delete individual tracks or artists from their detail pages if truly needed.

### Duplicate Detection
Playlists are considered duplicates if they contain the same tracks in the same order. The `unique_identifier` method on Playlist creates a signature by joining sorted track IDs.

### Active Storage
Used for two attachment types:
- Playlist cover art (JPG/PNG images)
- Track audio files (validated for audio content-type)

### Frontend Stack
- Turbo Rails for SPA-like navigation
- Stimulus.js for JavaScript controllers
- Bootstrap 5.3 CSS only (no Bootstrap JS - using native HTML5 controls instead)
  - **Why no Bootstrap JS**: Had importmap module resolution issues with Bootstrap + Popper.js dependencies
  - **Alternative**: Using native HTML5 elements (range inputs, tooltips via `title` attribute)
  - **Trade-off**: Less polished tooltips, but zero dependencies and simpler codebase
- Bootstrap Icons (fonts served from `public/fonts/`)
- Tom Select 2.4.3 (loaded via CDN `<script>` tag for searchable dropdowns, not via importmap due to plugin dependency issues)
- CSS bundling via SASS + PostCSS + Autoprefixer
- Importmap for JavaScript module management

## Database Schema Notes

- Join tables use composite indexes for efficient lookups
- Keys table has unique index on name to prevent duplicates
- Tracks have optional key_id foreign key (tracks can exist without keys)
- PlaylistsTrack has both primary key (id) and order column
- Active Storage tables follow Rails conventions
- always update CLAUDE.md

## Testing

### Running Tests
```bash
# Run all specs
bundle exec rspec

# Run specific spec file
bundle exec rspec spec/models/playlist_spec.rb

# Run specific test
bundle exec rspec spec/models/playlist_spec.rb:25
```

### Test Coverage
The application has comprehensive test coverage including:
- **Model specs**: All models (Playlist, Track, Artist, Key, PlaylistsTrack, DjSet, DjSetsTrack) with associations, validations, and methods
- **Service specs**: PlaylistImporter, CamelotWheelService, HarmonicMixingService, SetAnalysisService, PlaylistOptimizerService (38 examples)
- **Request specs**: All controllers (Playlists, Tracks, Artists, Keys, DjSets) with extensive tests for:
  - Server-side compatibility filtering on tracks index
  - BPM range filtering with enable/disable checkbox
  - Combined search and compatibility filtering
  - Pagination preservation across filter parameters
  - Invalid parameter handling
  - **DJ Sets**: Full CRUD operations, track management (add/remove/reorder), bulk operations, duplication, export, conversion to playlist

**DJ Sets Test Suite** (101 examples, 0 failures):
- Model validations (uniqueness, length constraints)
- Track ordering and resequencing
- Harmonic analysis integration
- Duplicate, export, and convert_to_playlist methods
- Controller actions: add_tracks, remove_track, remove_tracks (bulk), reorder_tracks
- Drag-and-drop reordering with harmonic score updates

### Test Infrastructure
- **RSpec 7.1**: Main testing framework
- **FactoryBot**: Test data factories for all models (including DJ Sets)
- **Faker**: Realistic fake data generation
- **Shoulda Matchers**: Simplified validation/association testing
- **ActiveSupport::Testing::TimeHelpers**: Time travel support for timestamp testing

### Code Quality
```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop --autocorrect-all
```

RuboCop is configured to enforce Rails and RSpec best practices while allowing flexibility for controller complexity and I18n requirements.