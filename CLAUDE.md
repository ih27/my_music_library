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

### File Organization

- `app/services/` - Business logic (currently just PlaylistImporter)
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
- Bootstrap 5.3 for UI components
- Bootstrap Icons
- CSS bundling via SASS + PostCSS + Autoprefixer

## Database Schema Notes

- Join tables use composite indexes for efficient lookups
- Keys table has unique index on name to prevent duplicates
- Tracks have optional key_id foreign key (tracks can exist without keys)
- PlaylistsTrack has both primary key (id) and order column
- Active Storage tables follow Rails conventions
