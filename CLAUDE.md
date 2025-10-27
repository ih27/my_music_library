# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

This is a Rails 8.1 music archive application for managing DJ playlists. It allows importing playlists from tab-delimited files, managing tracks with metadata (BPM, key, artists), and organizing music collections.

Ruby version: 3.3.10
Rails version: 8.1.0

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

## Architecture

### Core Data Models

**Playlist** - Container for ordered tracks
- Has many tracks through `playlists_tracks` join table
- Uses ActiveStorage for cover art attachments
- Auto-attaches default cover art on creation (`app/assets/images/default_cover_art.jpg`)
- Has `unique_identifier` method that creates track order signature for duplicate detection

**Track** - Individual music track
- Belongs to optional Key (musical key like "A Major", "C# Minor")
- Has many playlists through `playlists_tracks`
- Has and belongs to many Artists (HABTM relationship via `artists_tracks`)
- Uses ActiveStorage for audio file attachments
- Fields: name, bpm (decimal), time (in seconds), album, date_added
- Includes `search` class method for full-text search across track name, artist, key, BPM, and playlist

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

### Playlist Import System

**PlaylistImporter** (`app/services/playlist_importer.rb`)
- Parses tab-delimited files exported from DJ software
- Required headers: `#`, `Track Title`, `Artist`, `BPM`, `Date Added`
- Optional headers: `Key`, `Time`, `Album`
- Handles flexible column ordering (headers can be in any order)
- Uses rchardet (pure Ruby) for encoding detection (handles non-UTF-8 files)
- Processes BOM (Byte Order Mark) removal
- Creates/finds tracks, artists, and keys during import
- Validates duplicate playlists by comparing track IDs
- Wrapped in database transaction for atomicity
- Multiple artists per track supported (comma-separated in file)

### Controller Responsibilities

**PlaylistsController**
- Import: Creates playlist from uploaded file, extracts name from filename
- Show/Index: Display playlists
- Destroy: Deletes playlist and orphaned tracks/artists (cascading cleanup)
- Reorder: Updates track order via AJAX (uses `update_column` for performance)

**TracksController**
- Index with search functionality
- Individual track display
- Audio file upload endpoint

**ArtistsController & KeysController**
- Index and show views for browsing

### Harmonic Mixing System

**Overview**
The harmonic mixing feature helps DJs find compatible tracks and analyze playlist transitions using Camelot Wheel notation. All tracks have keys stored in Camelot format (e.g., "8A", "12B").

**CamelotWheelService** (`app/services/camelot_wheel_service.rb`)
- Parses Camelot notation: Format `[1-12][A|B]` where number = wheel position, letter = mode (A=Minor, B=Major)
- Calculates compatible keys based on harmonic mixing rules:
  - **Perfect**: Same key (8A → 8A)
  - **Smooth**: ±1 position (8A → 7A, 9A) or relative major/minor (8A ↔ 8B)
  - **Energy Boost**: +7 positions forward (8A → 3A)
  - **Rough**: All other transitions
- Computes harmonic flow score (0-100%) for playlists
- Formula: `(Perfect × 3 + Smooth × 2 + Energy × 2 + Rough × 0) / (total_transitions × 3) × 100`

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
- `Playlist#harmonic_flow_score` - Returns 0-100 score
- `Playlist#harmonic_analysis` - Full analysis with stats

**UI Features**
1. **Track Detail Page** (`tracks/show`): "Compatible Tracks" section with BPM slider (±0-20 BPM), results grouped by compatibility type
2. **Playlist Detail Page** (`playlists/show`): Harmonic flow score badge, transition quality indicators between tracks, quality breakdown stats
3. **Playlist Index** (`playlists/index`): Color-coded harmonic score badges on cards (green ≥75%, yellow ≥50%, red <50%)
4. **Tracks Index** (`tracks/index`): Searchable compatibility filter with BPM range (client-side filtering on current page only)

**Stimulus Controllers**
- `harmonic_filter_controller.js` - Handles BPM slider, checkbox toggle, track filtering, Tom Select dropdown
- `transition_indicator_controller.js` - Adds native browser tooltips to transition indicators using HTML `title` attribute (not Bootstrap tooltips - simpler, no dependencies)

### File Organization

- `app/services/` - Business logic (PlaylistImporter, CamelotWheelService, HarmonicMixingService)
- `app/models/concerns/` - Shared model mixins
- `app/assets/stylesheets/` - SCSS files (Bootstrap-based)
- `app/assets/builds/` - Compiled CSS output
- Database uses SQLite3 in all environments

## Important Implementation Details

### Character Encoding
The playlist importer handles various character encodings using the `rchardet` gem (pure Ruby, no native extensions). Files are detected for encoding and converted to UTF-8 with replacement characters for invalid sequences.

### Orphaned Record Cleanup
When deleting a playlist, the controller checks for orphaned tracks (tracks in no playlists) and orphaned artists (artists with no tracks) and removes them to keep the database clean.

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
- **Model specs**: All models (Playlist, Track, Artist, Key, PlaylistsTrack) with associations, validations, and methods
- **Service specs**: PlaylistImporter, CamelotWheelService, HarmonicMixingService
- **Request specs**: All controllers (Playlists, Tracks, Artists, Keys)

### Test Infrastructure
- **RSpec 7.1**: Main testing framework
- **FactoryBot**: Test data factories for all models
- **Faker**: Realistic fake data generation
- **Shoulda Matchers**: Simplified validation/association testing
- **DatabaseCleaner**: Ensures clean test database state

### Code Quality
```bash
# Run RuboCop
bundle exec rubocop

# Auto-fix violations
bundle exec rubocop --autocorrect-all
```

RuboCop is configured to enforce Rails and RSpec best practices while allowing flexibility for controller complexity and I18n requirements.