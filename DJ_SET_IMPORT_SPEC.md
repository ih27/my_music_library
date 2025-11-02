# DJ Set Import Specification

## Overview

Add the ability to import tracks into DJ Sets from tab-delimited files (same format as Playlists). This provides an alternative way to build DJ Sets and add tracks to the database, complementing the existing Set Builder feature.

## Motivation

Currently, there are two ways to add tracks to the database:
1. **Playlist Import**: Import retrospective playlists from Rekordbox exports
2. **DJ Set Import** (NEW): Import prospective or curated track collections

This feature enables users to:
- Import curated track lists from external sources (CSV/tab-delimited files)
- Build DJ Sets programmatically (e.g., from scripts or other tools)
- Bulk-add tracks to sets without manually selecting them one-by-one
- Reuse the existing Rekordbox export format for both Playlists and DJ Sets

## Key Differences: Playlists vs DJ Sets

| Feature | Playlists | DJ Sets |
|---------|-----------|---------|
| **Purpose** | Retrospective analysis | Prospective planning |
| **Editability** | Read-only after import | Fully editable |
| **Duplicate Detection** | Prevents duplicate playlists | Allows duplicate sets (different context) |
| **Cover Art** | Auto-attaches default cover | No cover art |
| **Import Behavior** | Creates new playlist | Adds to existing or creates new set |

## Refactoring Strategy

### 1. Extract Shared Import Logic

**Current State:**
- `PlaylistImporter` is tightly coupled to `Playlist` and `PlaylistsTrack` models
- File parsing, encoding detection, and track creation logic are mixed with playlist-specific logic

**Refactored State:**
- Create `TrackImporter` base service with shared logic:
  - File parsing and encoding detection
  - Header parsing and validation
  - Track/Artist/Key creation
  - Line processing
- `PlaylistImporter` and `DjSetImporter` inherit from `TrackImporter` and provide:
  - Model-specific association creation (PlaylistsTrack vs DjSetsTrack)
  - Validation logic (duplicate detection for Playlists, uniqueness for Sets)

### 2. Service Class Hierarchy

```ruby
# app/services/track_importer.rb (new base class)
class TrackImporter
  REQUIRED_HEADERS = ["#", "Track Title", "Artist", "BPM", "Date Added"].freeze
  OPTIONAL_HEADERS = %w[Key Time Album].freeze

  def initialize(file)
    @file = file
    @tracks_data = []
    @headers_map = {}
  end

  # Shared methods:
  # - parse_file
  # - parse_headers
  # - process_line
  # - detect_encoding
  # - sanitize_input
  # - convert_time_to_seconds
  # - tracks_data (getter)
end

# app/services/playlist_importer.rb (refactored)
class PlaylistImporter < TrackImporter
  def initialize(playlist, file)
    super(file)
    @playlist = playlist
  end

  def call
    parse_file if @file.present?
    return false if @tracks_data.empty?
    return false if duplicate_playlist?

    create_playlist_with_tracks
    true
  end

  private

  def create_playlist_with_tracks
    # Playlist-specific logic
  end

  def duplicate_playlist?
    # Existing duplicate detection
  end
end

# app/services/dj_set_importer.rb (new)
class DjSetImporter < TrackImporter
  def initialize(dj_set, file)
    super(file)
    @dj_set = dj_set
  end

  def call
    parse_file if @file.present?
    return false if @tracks_data.empty?

    create_dj_set_with_tracks
    true
  end

  private

  def create_dj_set_with_tracks
    # DJ Set-specific logic
    # - Create/find tracks
    # - Create DjSetsTrack associations
    # - No duplicate detection (allow multiple sets with same tracks)
  end
end
```

## UI/UX Changes

### 1. DJ Sets New/Create Form

**Current State:**
- Form with Name and Description fields only
- Integrates with Set Builder for adding tracks

**New State:**
- Add optional file upload field
- Two modes:
  - **Mode 1**: Create empty set (existing behavior)
  - **Mode 2**: Create set from file import (new behavior)

**Form Layout:**
```
DJ Set Name: [_________________]
Description: [_________________]
             [_________________]

Import Tracks (optional):
[Choose File] No file chosen

Note: You can create an empty set and add tracks later,
or import tracks from a tab-delimited file.

[Create DJ Set]
```

### 2. DJ Set Show Page Enhancement

**Current State:**
- Shows existing tracks with add/remove functionality

**New State:**
- Add "Import Tracks" button alongside "Add Tracks" button
- Opens modal with file upload field
- Appends imported tracks to end of existing tracks (maintains sequential order)

**Button Layout:**
```
[Add Tracks] [Import Tracks] [Export] [Duplicate] [Convert to Playlist]
```

## Import Behavior

### Creating New DJ Set with Import

1. User uploads file during set creation
2. Extract set name from filename (without extension)
3. Parse file and create tracks/artists/keys
4. Create DjSetsTrack associations with sequential order (1, 2, 3, ...)
5. **No duplicate detection** - allow importing similar track lists into multiple sets

### Adding Tracks to Existing DJ Set

1. User clicks "Import Tracks" on DJ Set show page
2. Upload file via modal
3. Parse file and create tracks/artists/keys
4. Append tracks to end of set (calculate next order from existing max)
5. Resequence all tracks to ensure sequential order
6. Redirect to set show page with success notice

## Technical Implementation Plan

### Phase 1: Refactor Existing Code
- [ ] Create `TrackImporter` base class
- [ ] Extract shared methods from `PlaylistImporter`
- [ ] Refactor `PlaylistImporter` to inherit from `TrackImporter`
- [ ] Update `PlaylistImporter` tests to ensure no regressions

### Phase 2: Implement DJ Set Import
- [ ] Create `DjSetImporter` service
- [ ] Add file upload to `dj_sets#new` form
- [ ] Update `dj_sets#create` controller action to handle file uploads
- [ ] Add import_tracks action to `DjSetsController`
- [ ] Create import modal on DJ Set show page

### Phase 3: Testing
- [ ] Add specs for `TrackImporter` base class
- [ ] Add specs for `DjSetImporter`
- [ ] Update controller specs for `dj_sets#create` with file upload
- [ ] Add request specs for `dj_sets#import_tracks`
- [ ] Ensure full CI suite passes

### Phase 4: Documentation
- [ ] Update CLAUDE.md with new import functionality
- [ ] Document refactored service class hierarchy
- [ ] Add examples of DJ Set import workflow

## Edge Cases & Validations

### File Validation
- **Empty file**: Show error "File cannot be empty"
- **Invalid headers**: Show error "Missing required header: [header_name]"
- **No valid tracks**: Show error "No valid tracks found in file"
- **Encoding errors**: Handle gracefully with replacement characters (existing behavior)

### DJ Set Validation
- **Name uniqueness**: Prevent importing into set with duplicate name
  - Approach: Append timestamp or counter to filename if name exists
  - Example: "My Set" → "My Set (2)" if "My Set" exists
- **Track uniqueness within set**: Prevent duplicate tracks in same set
  - Existing `DjSetsTrack` validation handles this
  - Skip duplicate track IDs during import with warning

### Track/Artist/Key Creation
- **Reuse existing logic**: `find_or_create_by!` ensures deduplication
- **Multiple artists**: Split on ", " and create associations (existing behavior)
- **Missing optional fields**: Allow nil values (existing behavior)

## Example File Format

```tsv
#	Track Title	Artist	BPM	Key	Time	Album	Date Added
1	Track One	Artist A	128.0	8A	4:32	Album 1	2025-01-01
2	Track Two	Artist B, Artist C	130.5	9A	5:15	Album 2	2025-01-02
3	Track Three	Artist A	126.0	8B	3:45	Album 1	2025-01-03
```

## Success Criteria

- [ ] DJ Sets can be created from file import
- [ ] Tracks can be appended to existing DJ Sets via import
- [ ] Shared import logic is DRY (no code duplication)
- [ ] All existing Playlist import functionality works unchanged
- [ ] Full test coverage (>85%)
- [ ] CI suite passes
- [ ] Documentation updated

## Future Enhancements (Out of Scope)

- Import from other formats (CSV, JSON, M3U playlists)
- Batch import multiple sets from folder
- Import validation preview before committing
- Import history/audit log
