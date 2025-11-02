# Set Builder - Feature Specification

**Status:** 📋 Planning Phase
**Created:** 2025-10-28
**Last Updated:** 2025-10-28

## Overview
A "Set Builder" feature that allows DJs to plan future sets by selecting tracks from the library and organizing them into prospective playlists. This feature distinguishes between:
- **Playlists**: Retrospective, imported from performed DJ sets (past)
- **Sets**: Prospective, manually curated for future performances (future)

## Core Concept

### Semantic Distinction
- **Playlist** = Past performance (imported via PlaylistImporter)
- **Set** = Future plan (built manually in the app)

This distinction helps DJs:
1. Archive historical performances separately from future plans
2. Experiment with track arrangements before performing
3. Leverage harmonic mixing analysis to optimize set flow
4. Build multiple set variations for different venues/moods
5. Convert finalized sets to playlists after performing them live

## Use Cases

### Use Case 1: Build a Set from Track Search
**Location:** `tracks/index` page

**User Story:** As a DJ, when browsing/searching my track library, I want to select multiple tracks and add them to a set so I can build a prospective playlist for an upcoming performance.

**UI Elements:**
- Checkbox on each track row for selection
- "Select All" / "Deselect All" bulk controls
- Fixed bottom toolbar appears when tracks are selected:
  - "Add X track(s) to set" button
  - Cancel button (clears selection)
- Modal/dropdown for set selection:
  - List of existing sets (with track count)
  - "Create new set" option with inline form (name + description)

**Behavior:**
- Track selection persists across pagination (stored in session storage)
- Modal shows track count being added
- After adding, show success message: "3 tracks added to [Set Name]"
- Option to navigate to set or continue browsing
- Duplicate tracks in set are prevented (uniqueness validation)

**Interaction Flow:**
```
1. User searches/filters tracks
2. User checks boxes for desired tracks
3. Bottom toolbar appears showing "5 tracks selected"
4. User clicks "Add to Set"
5. Modal opens: "Add to existing set" or "Create new set"
6. User selects/creates set
7. Tracks added to set with auto-incremented order
8. Success message shown with link to view set
```

### Use Case 2: View and Manage Sets
**Location:** `sets/index` page

**User Story:** As a DJ, I want to view all my planned sets with metadata so I can choose which one to work on or perform next.

**UI Elements:**
- Card grid layout (similar to playlists index)
- Each set card displays:
  - Set name (required)
  - Description (optional, truncated)
  - Track count
  - Total duration (computed from track lengths, formatted as HH:MM:SS)
  - Harmonic flow score badge (green ≥75%, yellow ≥50%, red <50%)
  - Average BPM (rounded to 1 decimal)
  - Last modified date
  - Quick action icons: View, Edit, Duplicate, Export, Delete
- "Create New Set" button (prominent, top-right)
- Sort options: Name, Date Modified, Track Count, Harmonic Score, Duration
- Visual distinction from playlists (see Visual Design section)

**Behavior:**
- Empty state: "No sets yet. Start building your first set!" with prominent CTA
- Delete confirmation modal (tracks are not deleted, only removed from set)
- Click card to navigate to set detail page
- Hover shows additional metadata tooltip

### Use Case 3: Set Detail and Editing
**Location:** `sets/show` page

**User Story:** As a DJ, when viewing a set, I want to see the track list with harmonic analysis, reorder tracks, remove tracks, and add more tracks.

**UI Elements:**
- **Header Section:**
  - Set name (editable inline or via edit button)
  - Description (editable, textarea with character count)
  - Metadata badges:
    - Track count
    - Total duration
    - Average BPM
    - Created/Modified dates
  - Harmonic flow score (prominent, large badge with percentage)
  - Action buttons:
    - Edit Metadata
    - Duplicate Set
    - Convert to Playlist
    - Export to File
    - Delete Set

- **Track List Section:**
  - Ordered track list (numbered 1, 2, 3...)
  - Each track row shows:
    - Drag handle icon (⋮⋮ or equivalent)
    - Track number
    - Track name (linked to track detail)
    - Artist name (linked to artist)
    - Key (Camelot notation)
    - BPM
    - Duration
    - Harmonic transition indicator to next track (🟢 🔵 ⚡ 🟡)
    - Remove button (X icon, appears on hover)
  - "Add More Tracks" button at bottom (opens track search modal)

- **Harmonic Analysis Section:**
  - Same as playlist analysis:
    - Overall harmonic flow score (0-100%)
    - Transition breakdown: X perfect, Y smooth, Z energy boost, N rough
    - Progress bar visualization of transition quality distribution

**Behavior:**
- **Drag-and-drop reordering:**
  - Drag tracks by handle to reorder
  - Visual feedback during drag (opacity, placeholder)
  - Real-time harmonic score updates after drop
  - AJAX save on drop
- **Remove track:**
  - Confirmation for single track removal
  - Track remains in database, only removed from set
  - Harmonic score recalculates
- **Add more tracks:**
  - Opens modal with track search/filter interface
  - Can add tracks from "Compatible Tracks" suggestions
  - Tracks added to end of list by default

**Interaction Flow:**
```
1. User navigates to set detail page
2. Views current track list with harmonic indicators
3. Drags track #5 to position #3
4. Harmonic score recalculates (e.g., 68% → 72%)
5. User adds more compatible tracks via "Add Tracks" button
6. Reviews updated harmonic flow
7. Exports or converts to playlist when satisfied
```

### Use Case 4: Create a New Set
**Location:** `sets/new` or inline modal

**User Story:** As a DJ, I want to create a new empty set or create one with initial tracks already selected.

**UI Elements:**
- Form fields:
  - **Name** (required, text input, max 100 chars)
  - **Description** (optional, textarea, max 500 chars)
- Submit: "Create Set" button
- Cancel button

**Behavior:**
- Can be accessed from:
  1. Sets index page ("Create New Set" button)
  2. Inline modal when adding tracks from tracks index
  3. Navigation menu (optional)
- After creation:
  - If created from tracks index with selected tracks: tracks are added immediately
  - If created empty: redirect to set show page with "Add Tracks" prompt
- Validation: name must be unique and present
- Success message: "[Set Name] created successfully"

### Use Case 5: Duplicate a Set
**Location:** `sets/show` page (action button)

**User Story:** As a DJ, I want to duplicate an existing set to create variations without starting from scratch.

**UI Elements:**
- "Duplicate" button in header actions
- Modal for new set details:
  - Pre-filled name: "[Original Name] (Copy)"
  - Pre-filled description: Same as original
  - Editable before creation

**Behavior:**
- Creates new set with same tracks in same order
- New set has unique name (validation enforced)
- Redirects to new set's show page
- Success message: "Duplicated as [New Set Name]"

**Related Feature: Convert Playlist to Set**
- On `playlists/show` page, add "Create Set from Playlist" button
- Same duplication flow as above
- Allows using past performances as templates for future sets

### Use Case 6: Convert Set to Playlist
**Location:** `sets/show` page (action button)

**User Story:** As a DJ, after performing a set live, I want to convert it to a playlist so I can track it as a past performance.

**UI Elements:**
- "Convert to Playlist" button in header actions
- Opens form modal similar to playlist import:
  - **Name** (pre-filled with set name, editable)
  - **Cover Art** (file upload, required)
  - **Description** (optional, inherits from set description)
  - Option: "Delete original set after conversion" (checkbox, default: unchecked)

**Behavior:**
- Creates new playlist with same tracks in same order
- Uploads cover art (ActiveStorage attachment)
- If "Delete original set" is checked: removes set after playlist creation
- Redirects to new playlist's show page
- Success message: "[Set Name] converted to playlist"

**Interaction Flow:**
```
1. User performs set live at venue
2. Returns home, navigates to set in app
3. Clicks "Convert to Playlist"
4. Uploads cover art (photo from venue or event flyer)
5. Optionally renames: "Friday Night at Club XYZ"
6. Checks "Delete original set"
7. Converts → Playlist created, set deleted
8. Views playlist with same tracks and harmonic analysis
```

### Use Case 7: Export Set to File
**Location:** `sets/show` page (action button)

**User Story:** As a DJ, I want to export my set to a tab-delimited file so I can import it into Rekordbox or other DJ software.

**UI Elements:**
- "Export to File" button in header actions
- Export format options (if multiple formats supported):
  - Tab-delimited text (.txt) - Rekordbox compatible
  - M3U playlist (.m3u) - Universal format (optional)
  - CSV (.csv) - Spreadsheet format (optional)

**Behavior:**
- Generates file with track data in same format as PlaylistImporter expects
- Includes all required headers: `#`, `Track Title`, `Artist`, `BPM`, `Key`, `Time`, `Album`, `Date Added`
- Filename: `[set_name]_[timestamp].txt`
- Triggers browser download
- Success message: "Set exported successfully"

**File Format (Tab-delimited):**
```
#	Track Title	Artist	BPM	Key	Time	Album	Date Added
1	Track Name 1	Artist 1	128.0	8A	5:23	Album 1	2025-10-28
2	Track Name 2	Artist 2	125.5	8B	4:45	Album 2	2025-10-27
...
```

**Integration Points:**
- Reuse column headers from `PlaylistImporter::REQUIRED_HEADERS`
- Ensure exported files can be re-imported via `playlists/import`
- Round-trip compatibility: Export → Import should recreate identical playlist

### Use Case 8: Edit Set Metadata
**Location:** `sets/edit` or inline editing on `sets/show`

**User Story:** As a DJ, I want to update a set's name and description as my plans evolve.

**UI Elements:**
- Same form as `sets/new`
- Pre-populated with existing data
- Save and Cancel buttons

**Behavior:**
- Inline editing preferred for show page (click to edit, save on blur)
- Separate edit page for full form experience
- Validation: name must be unique and present
- Track list is not edited here (only metadata)
- Success message: "Set updated"

### Use Case 9: Delete a Set
**Location:** `sets/show` or `sets/index`

**User Story:** As a DJ, I want to delete sets I no longer need without affecting the underlying tracks in my library.

**UI Elements:**
- Delete button with trash icon
- Confirmation modal:
  - "Are you sure you want to delete [Set Name]?"
  - "This will remove the set but not the tracks from your library"
  - Track count displayed
  - Confirm / Cancel buttons

**Behavior:**
- Set is destroyed
- Tracks remain in database (no cascade deletion)
- Orphaned associations in `sets_tracks` are cascade deleted
- Redirect to sets index after deletion
- Success message: "[Set Name] deleted"

## Data Model

### `Set` Model
```ruby
class Set < ApplicationRecord
  has_many :sets_tracks, dependent: :destroy
  has_many :tracks, through: :sets_tracks

  validates :name, presence: true, uniqueness: true
  validates :description, length: { maximum: 500 }, allow_blank: true

  # Methods:
  def total_duration
    # Sum of all track times in seconds
    tracks.sum(:time)
  end

  def total_duration_formatted
    # Format as HH:MM:SS or MM:SS
    seconds = total_duration
    Time.at(seconds).utc.strftime(seconds >= 3600 ? "%H:%M:%S" : "%M:%S")
  end

  def average_bpm
    # Average BPM of all tracks, rounded to 1 decimal
    return 0 if tracks.empty?
    (tracks.average(:bpm) || 0).round(1)
  end

  def harmonic_flow_score
    # Uses CamelotWheelService
    # Returns 0-100 percentage
    CamelotWheelService.harmonic_flow_score(analyze_transitions)
  end

  def analyze_transitions
    # Uses HarmonicMixingService
    # Returns array of transition hashes
    HarmonicMixingService.analyze_transitions(ordered_tracks)
  end

  def harmonic_analysis
    # Full analysis with stats: { score:, perfect_count:, smooth_count:, ... }
    transitions = analyze_transitions
    {
      score: harmonic_flow_score,
      total_transitions: transitions.size,
      perfect_count: transitions.count { |t| t[:quality] == :perfect },
      smooth_count: transitions.count { |t| t[:quality] == :smooth },
      energy_boost_count: transitions.count { |t| t[:quality] == :energy_boost },
      rough_count: transitions.count { |t| t[:quality] == :rough }
    }
  end

  def ordered_tracks
    # Returns tracks in order
    tracks.order('sets_tracks.order')
  end

  def duplicate(new_name: "#{name} (Copy)")
    # Create duplicate set with same tracks
    new_set = dup
    new_set.name = new_name
    new_set.save!

    sets_tracks.each do |st|
      new_set.sets_tracks.create!(track: st.track, order: st.order)
    end

    new_set
  end

  def export_to_file
    # Generate tab-delimited file content
    # Returns string for file download
  end

  def convert_to_playlist(name:, cover_art:, description: nil)
    # Create playlist from set
    # Params: name (string), cover_art (ActiveStorage attachment), description (string)
    # Returns Playlist object
  end
end
```

**Fields:**
- `id` (integer, primary key)
- `name` (string, required, unique)
- `description` (text, optional)
- `created_at` (datetime)
- `updated_at` (datetime)

### `SetsTrack` Join Model
```ruby
class SetsTrack < ApplicationRecord
  belongs_to :set
  belongs_to :track

  validates :order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :track_id, uniqueness: { scope: :set_id, message: "already in set" }

  default_scope { order(:order) }

  # Reorder helper method
  def self.reorder_tracks(set_id, track_ids_in_order)
    transaction do
      track_ids_in_order.each_with_index do |track_id, index|
        where(set_id: set_id, track_id: track_id)
          .update_all(order: index + 1)
      end
    end
  end
end
```

**Fields:**
- `id` (integer, primary key)
- `set_id` (integer, foreign key, required)
- `track_id` (integer, foreign key, required)
- `order` (integer, required, determines track sequence)
- `created_at` (datetime)
- `updated_at` (datetime)

**Indexes:**
- `set_id` (for efficient set queries)
- `track_id` (for efficient track lookups)
- `[set_id, track_id]` (unique composite index to prevent duplicates)
- `[set_id, order]` (for ordered retrieval)

### Database Migrations

#### Migration 1: Create Sets
```ruby
class CreateSets < ActiveRecord::Migration[8.1]
  def change
    create_table :sets do |t|
      t.string :name, null: false
      t.text :description
      t.timestamps
    end

    add_index :sets, :name, unique: true
  end
end
```

#### Migration 2: Create Sets-Tracks Join Table
```ruby
class CreateSetsTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :sets_tracks do |t|
      t.references :set, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :order, null: false
      t.timestamps
    end

    add_index :sets_tracks, [:set_id, :track_id], unique: true
    add_index :sets_tracks, [:set_id, :order]
  end
end
```

## Controller Actions

### `SetsController`
```ruby
class SetsController < ApplicationController
  before_action :set_set, only: [:show, :edit, :update, :destroy, :duplicate,
                                   :export, :convert_to_playlist, :add_tracks,
                                   :remove_track, :reorder_tracks]

  # GET /sets
  def index
    @sets = Set.includes(:tracks).order(sort_column => sort_direction)
    # Support sorting: name, updated_at, track_count, harmonic_score
  end

  # GET /sets/:id
  def show
    @tracks = @set.ordered_tracks.includes(:artists, :key)
    @harmonic_analysis = @set.harmonic_analysis
  end

  # GET /sets/new
  def new
    @set = Set.new
  end

  # POST /sets
  def create
    @set = Set.new(set_params)

    if @set.save
      # Add tracks if coming from track selection
      add_selected_tracks_to_set if params[:track_ids].present?
      redirect_to @set, notice: "#{@set.name} created successfully"
    else
      render :new, status: :unprocessable_entity
    end
  end

  # GET /sets/:id/edit
  def edit
    # Form for editing set metadata (name, description)
  end

  # PATCH /sets/:id
  def update
    if @set.update(set_params)
      redirect_to @set, notice: "Set updated"
    else
      render :edit, status: :unprocessable_entity
    end
  end

  # DELETE /sets/:id
  def destroy
    name = @set.name
    @set.destroy
    redirect_to sets_path, notice: "#{name} deleted"
  end

  # POST /sets/:id/add_tracks
  def add_tracks
    track_ids = params[:track_ids].reject(&:blank?)

    track_ids.each_with_index do |track_id, index|
      next_order = (@set.sets_tracks.maximum(:order) || 0) + index + 1
      @set.sets_tracks.create(track_id: track_id, order: next_order)
    end

    redirect_to @set, notice: "#{track_ids.size} track(s) added"
  end

  # DELETE /sets/:id/remove_track/:track_id
  def remove_track
    @set.sets_tracks.find_by(track_id: params[:track_id])&.destroy
    redirect_to @set, notice: "Track removed"
  end

  # POST /sets/:id/reorder_tracks
  def reorder_tracks
    SetsTrack.reorder_tracks(@set.id, params[:track_order])

    # Return updated harmonic score for AJAX response
    render json: {
      success: true,
      harmonic_score: @set.harmonic_flow_score
    }
  end

  # POST /sets/:id/duplicate
  def duplicate
    new_set = @set.duplicate(new_name: params[:name] || "#{@set.name} (Copy)")
    redirect_to new_set, notice: "Duplicated as #{new_set.name}"
  rescue ActiveRecord::RecordInvalid => e
    redirect_to @set, alert: "Error duplicating set: #{e.message}"
  end

  # GET /sets/:id/export
  def export
    content = @set.export_to_file
    filename = "#{@set.name.parameterize}_#{Time.current.to_i}.txt"

    send_data content,
              filename: filename,
              type: 'text/plain',
              disposition: 'attachment'
  end

  # POST /sets/:id/convert_to_playlist
  def convert_to_playlist
    playlist = @set.convert_to_playlist(
      name: params[:name],
      cover_art: params[:cover_art],
      description: params[:description]
    )

    @set.destroy if params[:delete_set] == '1'

    redirect_to playlist, notice: "Converted to playlist: #{playlist.name}"
  rescue => e
    redirect_to @set, alert: "Error converting: #{e.message}"
  end

  private

  def set_set
    @set = Set.find(params[:id])
  end

  def set_params
    params.require(:set).permit(:name, :description)
  end

  def sort_column
    %w[name updated_at].include?(params[:sort]) ? params[:sort] : 'updated_at'
  end

  def sort_direction
    %w[asc desc].include?(params[:direction]) ? params[:direction] : 'desc'
  end
end
```

### Routes
```ruby
resources :sets do
  member do
    post :add_tracks
    delete :remove_track
    post :reorder_tracks
    post :duplicate
    get :export
    post :convert_to_playlist
  end
end

# Optional: Add "Create Set from Playlist" on playlists controller
resources :playlists do
  member do
    post :create_set_from_playlist
  end
end
```

## Frontend Components

### Stimulus Controllers

#### `set-builder-controller.js`
**Purpose:** Manage track selection and "Add to Set" workflow on tracks index

**Targets:**
- `checkbox` - Individual track checkboxes
- `selectAll` - Select all checkbox
- `toolbar` - Bottom toolbar
- `selectedCount` - Display count of selected tracks
- `modal` - Set selection modal
- `setList` - List of existing sets in modal
- `newSetForm` - Inline form for creating new set

**Actions:**
- `toggleTrack()` - Handle individual checkbox, update toolbar visibility
- `toggleAll()` - Handle select/deselect all
- `showModal()` - Open set selection modal
- `addToSet(event)` - Submit tracks to selected set via AJAX
- `createSet(event)` - Create new set and add tracks
- `clearSelection()` - Clear all checkboxes and hide toolbar

**Values:**
- `selectedTracks` - Array of selected track IDs (stored in data attribute)

**Behavior:**
- Store selected track IDs in sessionStorage for pagination persistence
- Show/hide toolbar based on selection count
- AJAX form submission for adding tracks (avoid page reload)

#### `set-editor-controller.js`
**Purpose:** Handle drag-and-drop reordering and track removal on set show page

**Targets:**
- `trackList` - Sortable track list container
- `trackRow` - Individual track rows
- `harmonicScore` - Harmonic score display element

**Actions:**
- `dragStart(event)` - Initialize drag with track ID
- `dragOver(event)` - Allow drop (prevent default)
- `drop(event)` - Handle drop, reorder tracks, submit via AJAX
- `removeTrack(event)` - Remove track with confirmation, update via AJAX
- `updateHarmonicScore(newScore)` - Update score display after reorder

**Values:**
- `draggedTrackId` - Currently dragged track ID
- `setId` - Current set ID for AJAX requests

**Libraries:**
- Native HTML5 Drag and Drop API (no external dependencies)

#### `set-modal-controller.js`
**Purpose:** Manage modals for set actions (convert to playlist, duplicate, etc.)

**Targets:**
- `form` - Modal form element
- `coverArtInput` - Cover art file input (for convert to playlist)
- `deleteSetCheckbox` - Delete original set checkbox

**Actions:**
- `open()` - Open modal
- `close()` - Close modal
- `submit(event)` - Handle form submission with validation

**Behavior:**
- Validate required fields (name, cover art for convert)
- Show preview of uploaded cover art
- Disable submit until validation passes

### Views

#### `sets/index.html.erb`
```erb
<div class="container py-4">
  <div class="d-flex justify-content-between align-items-center mb-4">
    <h1><%= icon 'music-note-list' %> My Sets</h1>
    <%= link_to 'Create New Set', new_set_path, class: 'btn btn-primary' %>
  </div>

  <% if @sets.empty? %>
    <div class="text-center py-5">
      <p class="text-muted">No sets yet. Start building your first set!</p>
      <%= link_to 'Browse Tracks', tracks_path, class: 'btn btn-primary' %>
    </div>
  <% else %>
    <div class="row">
      <% @sets.each do |set| %>
        <div class="col-md-4 mb-4">
          <%= render 'set_card', set: set %>
        </div>
      <% end %>
    </div>
  <% end %>
</div>
```

#### `sets/_set_card.html.erb`
```erb
<div class="card set-card h-100">
  <div class="card-body">
    <!-- Harmonic score badge at top -->
    <div class="harmonic-badge-container">
      <%= render 'harmonic_badge', score: set.harmonic_flow_score %>
    </div>

    <!-- Set name and description -->
    <h5 class="card-title">
      <%= link_to set.name, set_path(set) %>
    </h5>
    <p class="card-text text-muted">
      <%= truncate(set.description, length: 100) %>
    </p>

    <!-- Metadata -->
    <div class="set-metadata">
      <div><%= icon 'music-note' %> <%= set.tracks.size %> tracks</div>
      <div><%= icon 'clock' %> <%= set.total_duration_formatted %></div>
      <div><%= icon 'speedometer' %> <%= set.average_bpm %> BPM</div>
      <div><%= icon 'calendar' %> <%= time_ago_in_words(set.updated_at) %> ago</div>
    </div>

    <!-- Action buttons -->
    <div class="btn-group mt-3" role="group">
      <%= link_to set_path(set), class: 'btn btn-sm btn-outline-primary' do %>
        <%= icon 'eye' %> View
      <% end %>
      <%= link_to edit_set_path(set), class: 'btn btn-sm btn-outline-secondary' do %>
        <%= icon 'pencil' %> Edit
      <% end %>
      <%= link_to export_set_path(set), method: :get, class: 'btn btn-sm btn-outline-success' do %>
        <%= icon 'download' %> Export
      <% end %>
    </div>
  </div>
</div>
```

#### `sets/show.html.erb`
```erb
<div class="container py-4">
  <!-- Header -->
  <div class="d-flex justify-content-between align-items-start mb-4">
    <div>
      <h1><%= @set.name %></h1>
      <p class="text-muted"><%= @set.description %></p>

      <!-- Metadata badges -->
      <div class="d-flex gap-2 mb-3">
        <span class="badge bg-secondary"><%= @set.tracks.size %> tracks</span>
        <span class="badge bg-secondary"><%= @set.total_duration_formatted %></span>
        <span class="badge bg-secondary"><%= @set.average_bpm %> BPM</span>
      </div>

      <!-- Harmonic score (large, prominent) -->
      <%= render 'harmonic_score', score: @harmonic_analysis[:score] %>
    </div>

    <!-- Action buttons -->
    <div class="btn-group-vertical">
      <%= link_to 'Edit', edit_set_path(@set), class: 'btn btn-outline-secondary' %>
      <%= button_to 'Duplicate', duplicate_set_path(@set), method: :post,
                    class: 'btn btn-outline-primary' %>
      <%= button_to 'Convert to Playlist', '#',
                    class: 'btn btn-outline-success',
                    data: { bs_toggle: 'modal', bs_target: '#convertModal' } %>
      <%= link_to 'Export', export_set_path(@set), class: 'btn btn-outline-success' %>
      <%= button_to 'Delete', set_path(@set), method: :delete,
                    class: 'btn btn-outline-danger',
                    data: { confirm: "Delete #{@set.name}?" } %>
    </div>
  </div>

  <!-- Track list with drag-and-drop -->
  <div data-controller="set-editor" data-set-editor-set-id-value="<%= @set.id %>">
    <div class="card">
      <div class="card-header">
        <h5>Track List</h5>
      </div>
      <div class="list-group list-group-flush" data-set-editor-target="trackList">
        <%= render 'track_list', tracks: @tracks %>
      </div>
      <div class="card-footer">
        <%= link_to 'Add More Tracks', tracks_path(set_id: @set.id),
                    class: 'btn btn-primary' %>
      </div>
    </div>
  </div>

  <!-- Harmonic analysis section -->
  <div class="card mt-4">
    <div class="card-header">
      <h5>Harmonic Analysis</h5>
    </div>
    <div class="card-body">
      <%= render 'harmonic_analysis', analysis: @harmonic_analysis %>
    </div>
  </div>
</div>

<!-- Convert to Playlist Modal -->
<%= render 'convert_to_playlist_modal', set: @set %>
```

#### `sets/_convert_to_playlist_modal.html.erb`
```erb
<div class="modal fade" id="convertModal" data-controller="set-modal">
  <div class="modal-dialog">
    <div class="modal-content">
      <%= form_with url: convert_to_playlist_set_path(set),
                    method: :post,
                    multipart: true,
                    data: { set_modal_target: 'form' } do |f| %>
        <div class="modal-header">
          <h5 class="modal-title">Convert to Playlist</h5>
          <button type="button" class="btn-close" data-bs-dismiss="modal"></button>
        </div>

        <div class="modal-body">
          <!-- Name -->
          <div class="mb-3">
            <%= f.label :name, 'Playlist Name', class: 'form-label' %>
            <%= f.text_field :name, value: set.name, class: 'form-control', required: true %>
          </div>

          <!-- Cover Art (required) -->
          <div class="mb-3">
            <%= f.label :cover_art, 'Cover Art', class: 'form-label' %>
            <%= f.file_field :cover_art,
                             accept: 'image/*',
                             class: 'form-control',
                             required: true,
                             data: { set_modal_target: 'coverArtInput' } %>
            <small class="text-muted">Required for playlists</small>
          </div>

          <!-- Description (optional) -->
          <div class="mb-3">
            <%= f.label :description, class: 'form-label' %>
            <%= f.text_area :description, value: set.description,
                            class: 'form-control', rows: 3 %>
          </div>

          <!-- Delete original set checkbox -->
          <div class="form-check">
            <%= f.check_box :delete_set,
                            class: 'form-check-input',
                            data: { set_modal_target: 'deleteSetCheckbox' } %>
            <%= f.label :delete_set, 'Delete original set after conversion',
                        class: 'form-check-label' %>
          </div>
        </div>

        <div class="modal-footer">
          <button type="button" class="btn btn-secondary" data-bs-dismiss="modal">Cancel</button>
          <%= f.submit 'Convert to Playlist', class: 'btn btn-success' %>
        </div>
      <% end %>
    </div>
  </div>
</div>
```

#### `sets/new.html.erb` and `sets/edit.html.erb`
```erb
<div class="container py-4">
  <h1><%= @set.new_record? ? 'Create New Set' : 'Edit Set' %></h1>
  <%= render 'form', set: @set %>
</div>
```

#### `sets/_form.html.erb`
```erb
<%= form_with model: set, class: 'card' do |f| %>
  <div class="card-body">
    <!-- Name -->
    <div class="mb-3">
      <%= f.label :name, class: 'form-label' %>
      <%= f.text_field :name, class: 'form-control', required: true, maxlength: 100 %>
      <% if set.errors[:name].any? %>
        <div class="text-danger"><%= set.errors[:name].first %></div>
      <% end %>
    </div>

    <!-- Description -->
    <div class="mb-3">
      <%= f.label :description, class: 'form-label' %>
      <%= f.text_area :description, class: 'form-control', rows: 4, maxlength: 500 %>
      <small class="text-muted">
        <%= set.description&.length || 0 %> / 500 characters
      </small>
    </div>
  </div>

  <div class="card-footer">
    <%= f.submit class: 'btn btn-primary' %>
    <%= link_to 'Cancel', set.new_record? ? sets_path : set_path(set),
                class: 'btn btn-secondary' %>
  </div>
<% end %>
```

#### `tracks/index.html.erb` (Enhanced)
```erb
<!-- Add checkboxes and selection toolbar -->
<div data-controller="set-builder">
  <table class="table">
    <thead>
      <tr>
        <th>
          <input type="checkbox"
                 data-set-builder-target="selectAll"
                 data-action="change->set-builder#toggleAll">
        </th>
        <th>Track</th>
        <th>Artist</th>
        <!-- ... other columns ... -->
      </tr>
    </thead>
    <tbody>
      <% @tracks.each do |track| %>
        <tr>
          <td>
            <input type="checkbox"
                   value="<%= track.id %>"
                   data-set-builder-target="checkbox"
                   data-action="change->set-builder#toggleTrack">
          </td>
          <td><%= track.name %></td>
          <!-- ... other cells ... -->
        </tr>
      <% end %>
    </tbody>
  </table>

  <!-- Fixed bottom toolbar (hidden by default) -->
  <div class="set-builder-toolbar" data-set-builder-target="toolbar">
    <div class="container">
      <span data-set-builder-target="selectedCount">0 tracks selected</span>
      <button class="btn btn-primary"
              data-action="click->set-builder#showModal">
        Add to Set
      </button>
      <button class="btn btn-secondary"
              data-action="click->set-builder#clearSelection">
        Cancel
      </button>
    </div>
  </div>

  <!-- Set selection modal -->
  <%= render 'set_selection_modal' %>
</div>
```

### CSS Styles

```scss
// app/assets/stylesheets/_sets.scss

// Set builder toolbar
.set-builder-toolbar {
  position: fixed;
  bottom: 0;
  left: 0;
  right: 0;
  background: #fff;
  border-top: 2px solid #28a745; // Green for "sets"
  padding: 1rem;
  box-shadow: 0 -2px 10px rgba(0, 0, 0, 0.1);
  z-index: 1000;
  display: none;

  &.active {
    display: flex;
    justify-content: space-between;
    align-items: center;
  }

  .container {
    display: flex;
    justify-content: space-between;
    align-items: center;
    width: 100%;
  }
}

// Set card styling
.set-card {
  border-left: 4px solid #28a745; // Green accent for sets
  transition: transform 0.2s, box-shadow 0.2s;

  &:hover {
    transform: translateY(-4px);
    box-shadow: 0 4px 12px rgba(0, 0, 0, 0.15);
  }

  .set-metadata {
    font-size: 0.875rem;
    color: #6c757d;

    > div {
      margin-bottom: 0.25rem;
    }
  }

  .harmonic-badge-container {
    position: absolute;
    top: 0.5rem;
    right: 0.5rem;
  }
}

// Playlist card styling (for comparison)
.playlist-card {
  border-left: 4px solid #007bff; // Blue accent for playlists
}

// Track list in set editor
.set-editor {
  .track-list {
    list-style: none;
    padding: 0;
  }

  .track-row {
    display: flex;
    align-items: center;
    padding: 0.75rem;
    border-bottom: 1px solid #dee2e6;
    transition: background 0.2s;

    &:hover {
      background: #f8f9fa;

      .remove-track-btn {
        opacity: 1;
      }
    }

    &.dragging {
      opacity: 0.5;
      background: #e9ecef;
    }

    &.drag-over {
      border-top: 2px solid #007bff;
    }

    .drag-handle {
      cursor: move;
      color: #6c757d;
      margin-right: 1rem;
      font-size: 1.2rem;

      &:hover {
        color: #495057;
      }
    }

    .track-number {
      font-weight: bold;
      margin-right: 1rem;
      min-width: 2rem;
    }

    .track-info {
      flex: 1;
    }

    .remove-track-btn {
      opacity: 0;
      transition: opacity 0.2s;
      color: #dc3545;
      cursor: pointer;

      &:hover {
        color: #c82333;
      }
    }
  }
}

// Harmonic score (large, prominent)
.harmonic-score-large {
  display: inline-block;
  padding: 1rem 1.5rem;
  border-radius: 0.5rem;
  font-size: 2rem;
  font-weight: bold;

  &.score-high {
    background: #d4edda;
    color: #155724;
    border: 2px solid #28a745;
  }

  &.score-medium {
    background: #fff3cd;
    color: #856404;
    border: 2px solid #ffc107;
  }

  &.score-low {
    background: #f8d7da;
    color: #721c24;
    border: 2px solid #dc3545;
  }
}

// Visual distinction helpers
.icon-set {
  color: #28a745; // Green for sets
}

.icon-playlist {
  color: #007bff; // Blue for playlists
}
```

## Visual Design: Sets vs Playlists

### Color Scheme
- **Playlists (Past)**: Blue theme (`#007bff`)
  - Blue left border on cards
  - Blue badges and buttons
  - Icon: 📼 or 🎵

- **Sets (Future)**: Green theme (`#28a745`)
  - Green left border on cards
  - Green badges and buttons
  - Icon: 🎧 or 🎛️

### Navigation
```
Music Archive
├── 🏠 Home
├── 🎵 Playlists (Imported)
├── 🎧 Sets (Planned)
├── 🎼 Tracks
├── 👤 Artists
└── 🎹 Keys
```

### Typography
- **Playlists page title**: "My Playlists" with subtitle "Imported DJ sets from past performances"
- **Sets page title**: "My Sets" with subtitle "Planned sets for future performances"

### Iconography
| Element | Playlists | Sets |
|---------|-----------|------|
| Main icon | 📼 (`bi-vinyl`) | 🎧 (`bi-headphones`) |
| Card border | Blue (left) | Green (left) |
| Action buttons | Blue outline | Green outline |
| Success messages | Blue background | Green background |

## Dependencies & Libraries

### Backend (Ruby Gems)
**No additional gems required** - Leverages existing Rails functionality and harmonic mixing services.

### Frontend (JavaScript Packages)

#### Native HTML5 Drag and Drop API
**No package needed** - Using native browser API

**Why:**
- Zero dependencies
- Sufficient for single-dimension (vertical) drag-and-drop
- Simple track reordering use case

**Implementation:**
```javascript
// set-editor-controller.js
dragStart(event) {
  event.dataTransfer.effectAllowed = 'move'
  event.dataTransfer.setData('trackId', event.target.dataset.trackId)
  event.target.classList.add('dragging')
}

drop(event) {
  event.preventDefault()
  const trackId = event.dataTransfer.getData('trackId')
  // Reorder logic + AJAX save
}
```

#### Stimulus (Already Installed)
- `set-builder-controller.js` - Track selection and add to set
- `set-editor-controller.js` - Drag-and-drop reordering
- `set-modal-controller.js` - Modal management

#### Bootstrap 5 (Already Installed)
- Modals for set selection and conversion
- Card grid layout for sets index
- Form components

## Implementation Plan

### Phase 1: Backend Foundation ✅
**Goal:** Database, models, basic CRUD

1. Create migrations: `sets`, `sets_tracks`
2. Create models: `Set`, `SetsTrack`
3. Add associations and validations
4. Add harmonic analysis methods to `Set` (reuse from `Playlist`)
5. Run migrations and test in console

**Acceptance Criteria:**
- Can create sets via console
- Can add tracks to sets with order
- Harmonic analysis methods return correct data

### Phase 2: Controllers & Routes ✅
**Goal:** RESTful CRUD endpoints

1. Generate `SetsController`
2. Implement standard actions: `index`, `show`, `new`, `create`, `edit`, `update`, `destroy`
3. Implement custom actions: `add_tracks`, `remove_track`, `reorder_tracks`
4. Configure routes
5. Add basic error handling

**Acceptance Criteria:**
- All routes accessible
- CRUD operations work via console/Postman
- Error handling for invalid params

### Phase 3: Basic Views (CRUD) ✅
**Goal:** Functional UI for creating/viewing sets

1. `sets/index.html.erb` - List sets with cards
2. `sets/show.html.erb` - Display set with track list (static, no drag-drop yet)
3. `sets/new.html.erb` and `sets/edit.html.erb` - Forms
4. `sets/_form.html.erb` - Shared form partial
5. Add basic CSS styling

**Acceptance Criteria:**
- Can create set via web form
- Can view sets in card grid
- Can edit and delete sets
- Responsive layout

### Phase 4: Track Selection UI ✅
**Goal:** Select tracks from tracks index and add to set

1. Add checkboxes to `tracks/index.html.erb`
2. Add "Select All" functionality
3. Create fixed bottom toolbar (hidden by default)
4. Create set selection modal with:
   - List of existing sets
   - "Create new set" inline form
5. Implement `set-builder-controller.js`
6. Style toolbar and modal
7. Add sessionStorage for pagination persistence

**Acceptance Criteria:**
- Can select tracks with checkboxes
- Toolbar appears when tracks selected
- Can add to existing set or create new
- Selection persists across pagination
- Success message after adding

### Phase 5: Drag-and-Drop Reordering ✅
**Goal:** Reorder tracks in set with visual feedback

1. Add drag handles to track rows in `sets/show.html.erb`
2. Implement `set-editor-controller.js` with:
   - `dragStart`, `dragOver`, `drop` actions
   - AJAX call to `reorder_tracks` endpoint
   - Visual feedback (opacity, placeholder)
3. Add CSS for drag states
4. Update harmonic score in real-time after reorder

**Acceptance Criteria:**
- Can drag tracks to reorder
- Visual feedback during drag
- Harmonic score updates after drop
- Changes persist (AJAX save)

### Phase 6: Advanced Features ✅
**Goal:** Duplicate, export, convert functionality

1. **Duplicate Set:**
   - Add `duplicate` action to controller
   - Add button to sets show page
   - Add modal for renaming

2. **Export to File:**
   - Implement `Set#export_to_file` method
   - Generate tab-delimited content matching PlaylistImporter format
   - Add `export` action and route
   - Add "Export" button to sets show page

3. **Convert to Playlist:**
   - Create conversion modal with cover art upload
   - Implement `Set#convert_to_playlist` method
   - Handle "Delete original set" checkbox
   - Redirect to new playlist after conversion

4. **Create Set from Playlist:**
   - Add "Create Set from Playlist" button to playlists show page
   - Reuse duplication logic

**Acceptance Criteria:**
- Can duplicate sets with new names
- Exported files can be re-imported as playlists
- Converted sets become playlists with cover art
- Can use playlists as set templates

### Phase 7: Polish & Visual Design ✅
**Goal:** Professional UI with clear Sets vs Playlists distinction

1. Add color scheme (green for sets, blue for playlists)
2. Add icons to navigation and cards
3. Add border accents to cards
4. Improve hover states and transitions
5. Add loading states for AJAX actions
6. Add success/error flash messages
7. Ensure responsive design on mobile

**Acceptance Criteria:**
- Clear visual distinction between sets and playlists
- Smooth animations and transitions
- Professional, polished appearance
- Mobile-friendly

### Phase 8: Testing ✅
**Goal:** Comprehensive test coverage (target: >85%)

1. **Model specs:**
   - `Set`: validations, associations, methods
   - `SetsTrack`: validations, ordering
   - `Set#total_duration`, `#average_bpm`, `#harmonic_flow_score`

2. **Controller specs:**
   - All CRUD actions with valid/invalid params
   - Custom actions: add_tracks, remove_track, reorder_tracks
   - Duplicate, export, convert actions

3. **Request specs (Integration):**
   - Full workflow: create → add tracks → reorder → convert
   - Track selection → add to set workflow
   - Export and re-import round-trip

4. **System specs (Capybara + JavaScript):**
   - Select tracks with checkboxes
   - Drag-and-drop reordering (if feasible with Capybara)
   - Modal interactions

**Acceptance Criteria:**
- Test coverage >85%
- All critical paths tested
- Edge cases covered (empty sets, duplicate tracks, etc.)
- `bin/ci` passes

### Phase 9: Documentation ✅
**Goal:** Update project documentation

1. Update `CLAUDE.md`:
   - Add Set Builder architecture section
   - Document models, controllers, services
   - Update workflow instructions
   - Add development commands

2. Update `SET_BUILDER_SPEC.md`:
   - Mark as "Implemented"
   - Add implementation notes
   - Document deviations from spec

3. Create helpful code comments

**Acceptance Criteria:**
- `CLAUDE.md` reflects new architecture
- `SET_BUILDER_SPEC.md` finalized
- Code is well-commented

## Testing Considerations

### Model Tests
- `Set` validations (name presence, uniqueness, description length)
- `Set` associations (has_many :tracks through :sets_tracks)
- `Set#total_duration` calculation (sum of track times)
- `Set#average_bpm` calculation with edge cases (empty set, nil BPMs)
- `Set#harmonic_flow_score` accuracy (reuses CamelotWheelService)
- `Set#analyze_transitions` returns correct transition objects
- `Set#duplicate` creates new set with same tracks
- `Set#export_to_file` generates valid tab-delimited content
- `Set#convert_to_playlist` creates playlist with cover art
- `SetsTrack` validations (order, track uniqueness within set)
- `SetsTrack` ordering (default scope)

### Controller Tests
- `SetsController#index` renders set list with sorting
- `SetsController#show` displays set with tracks and analysis
- `SetsController#create` with valid/invalid params
- `SetsController#update` with valid/invalid params
- `SetsController#destroy` removes set, preserves tracks
- `SetsController#add_tracks` adds tracks with proper order
- `SetsController#remove_track` removes track from set
- `SetsController#reorder_tracks` updates order correctly, returns updated score
- `SetsController#duplicate` creates new set with unique name
- `SetsController#export` sends file with correct content-type
- `SetsController#convert_to_playlist` creates playlist with cover art

### Request Specs (Integration)
- **Full workflow:** Create set → Add tracks → Reorder → Remove track → Delete set
- **Track selection workflow:** Browse tracks → Select → Add to new set → View set
- **Add to existing set:** Select tracks → Add to existing set → Verify count
- **Duplicate set:** Duplicate → Rename → Verify tracks copied
- **Export/import round-trip:** Create set → Export → Import as playlist → Compare
- **Convert set:** Create set → Convert to playlist → Verify playlist created
- **Error handling:** Invalid names, missing cover art, etc.

### System Specs (JavaScript/Capybara)
- Select tracks via checkboxes → Toolbar appears with count
- Click "Add to Set" → Modal opens → Create new set → Success message
- Select tracks → Add to existing set → Success
- View set → Remove track → Track disappears, score updates
- Drag-and-drop track reordering → Order updates (if feasible with Capybara)

### Edge Cases to Test
- Empty set (0 tracks): Should allow creation, show appropriate messages
- Set with 1 track: Harmonic analysis should handle gracefully (0 transitions)
- Duplicate track prevention: Should not allow same track twice in set
- Set name uniqueness: Should prevent duplicate names
- Orphaned tracks: After removing from set, tracks should remain in database
- Large sets (100+ tracks): Performance testing for reordering and analysis
- Export special characters: Track names with quotes, tabs, newlines

## Database Impact

### New Tables
- **sets**: Stores set metadata (name, description, timestamps)
- **sets_tracks**: Join table with order column for track sequencing

### Indexes
- `sets.name` (unique) - Enforce name uniqueness, speed up lookups
- `sets_tracks.set_id` - Efficient set queries
- `sets_tracks.track_id` - Efficient track lookups
- `sets_tracks[set_id, track_id]` (unique composite) - Prevent duplicate tracks
- `sets_tracks[set_id, order]` - Efficient ordered retrieval

### No Changes to Existing Tables
- `playlists`, `tracks`, `artists`, `keys` remain unchanged
- Sets and playlists are completely independent entities

## Performance Considerations

### Database Queries
- Use `includes(:tracks, :artists, :key)` to eager load associations
- Harmonic analysis computed on-demand (not cached initially)
- Consider caching harmonic score if performance becomes an issue

### File Export
- Export generates string in memory (no temp files)
- Large sets (1000+ tracks) may need streaming approach

### Real-time Updates
- Drag-and-drop reordering uses AJAX to avoid full page reload
- Harmonic score recalculates after reorder (may be slow for large sets)
- Consider debouncing or background job for large sets

### Future Optimizations
- Cache harmonic scores in database column
- Background job for export of large sets
- Pagination for sets with 100+ tracks

## Security Considerations

### File Upload (Cover Art for Conversion)
- Validate file type: `content_type: ['image/png', 'image/jpg', 'image/jpeg']`
- Validate file size: Max 5MB
- Use ActiveStorage validations
- Scan for malware (future: integrate virus scanner)

### Parameter Validation
- Strong parameters for all controller actions
- Validate track_ids are integers
- Validate order values are positive integers

### Authorization (Future)
- Currently no user authentication
- Future: Add user ownership (sets belong to users)
- Prevent unauthorized access to other users' sets

## Open Questions - RESOLVED

### 1. Duplicate Track Handling ✅
**Decision:** Prevent duplicates via unique constraint on `[set_id, track_id]`
- Rationale: Cleaner data model, avoid confusion
- If DJs need to play a track twice, they can add it to the playlist manually after performing

### 2. Set Capacity ✅
**Decision:** No hard limit
- User confirmed: No limit on set size

### 3. Track Selection Persistence ✅
**Decision:** Session storage (cleared on page refresh)
- Rationale: Simpler implementation for V1
- Future: Upgrade to localStorage if users request persistence

### 4. Default Track Order ✅
**Decision:** Order of selection (1st clicked = 1st in set)
- Rationale: More intuitive for DJs building sets

### 5. Set Visibility ✅
**Decision:** All sets private (no sharing features in V1)
- Future: Add public/private toggle and sharing

### 6. Drag-and-Drop Library ✅
**Decision:** Native HTML5 Drag API
- Rationale: Zero dependencies, sufficient for vertical reordering
- If too complex: Migrate to SortableJS in V2

### 7. Performance → Playlist Conversion ✅
**Decision:** Yes! "Convert to Playlist" button with cover art upload
- User confirmed: Excited about this feature
- Implementation: Modal form similar to playlist import

### 8. Empty Set Handling ✅
**Decision:** Yes, allow empty sets
- Rationale: Supports gradual set building over time

### 9. Set Export ✅
**Decision:** Yes! Export to tab-delimited format
- User confirmed: Very excited about this feature
- Format: Same as PlaylistImporter expects (round-trip compatible)

### 10. Set Duplication ✅
**Decision:** Yes! Duplicate sets and convert playlists to sets
- User confirmed: Useful for creating variations
- Implementation: Both "Duplicate Set" and "Create Set from Playlist"

### 11. Visual Distinction ✅
**Decision:** Color-coded (green for sets, blue for playlists)
- User confirmed: Wants distinction but unsure how
- Proposal: Green theme for sets (future), blue for playlists (past)
- Icons: 🎧 for sets, 📼 for playlists

## Future Enhancements (Out of Scope for V1)

### Phase 2 Features (Post-MVP)
1. **Set Tags/Categories**
   - Tag sets: "House", "Techno", "Warm-up", "Peak Time"
   - Filter sets by tags

2. **Set Templates**
   - Save set as template (structure without specific tracks)
   - Template library: "2-hour club set", "Festival opener"

3. **Performance Tracking**
   - Mark set as "Performed" with date and venue
   - Performance history timeline
   - Stats: Most performed tracks, venues, etc.

4. **Set Sharing**
   - Generate shareable link for set view (read-only)
   - Export set as PDF with track list and analysis

5. **AI-Assisted Set Building**
   - "Suggest next track" based on harmonic compatibility
   - "Auto-optimize order" for best harmonic flow
   - "Find similar sets" based on track/key patterns

6. **Set Collaboration**
   - Share set with other DJs for feedback
   - Collaborative editing (multiple users)
   - Comments on tracks

7. **Mobile Optimization**
   - Simplified mobile view for on-the-go editing
   - Touch-friendly drag-and-drop
   - Mobile-optimized track selection

8. **Set Analytics**
   - Track usage across sets
   - Most-used keys and BPM ranges
   - Average set length and flow scores
   - Genre distribution

9. **Multiple Export Formats**
   - M3U playlist format
   - CSV format
   - JSON API export

10. **Set Versioning**
    - Track changes over time
    - "Undo" functionality
    - Compare versions side-by-side

### Advanced Features (Future Consideration)
- Integration with DJ hardware (export directly to USB)
- BPM/key change recommendations for better flow
- Real-time set duration tracking with target length
- Set scheduling calendar (assign sets to gig dates)
- Setlist.fm integration (import performed setlists)
- Spotify playlist export
- Automatic BPM/key detection for imported audio files

---

**Specification Status:** 📋 Planning Complete - Ready for Implementation

**Next Steps:**
1. ✅ Finalize spec with user feedback
2. ✅ Begin implementation (Phase 1: Backend Foundation)
3. Iterate through phases 1-9
4. Run `bin/ci` after each phase
5. Deploy and gather user feedback
