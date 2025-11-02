# Manual Testing Checklist - Set Builder Feature

**Purpose:** Test all Set Builder features before finalizing with automated tests and documentation.

**Setup:** Start the server with `bin/dev` and navigate to `http://localhost:3000`

---

## ✅ Section 1: Navigation & Visual Distinction

### Test 1.1: Navigation Menu

- [x] Check navigation bar at top of page
- [x] Verify "Playlists" link has blue music note icon
- [x] Verify "Sets" link has green headphones icon
- [x] Click "Sets" link → Should navigate to `/dj_sets`
- [x] Click "Playlists" link → Should navigate to `/playlists`

### Test 1.2: Visual Distinction

- [x] Navigate to Playlists index
- [x] Observe playlist cards have **blue left border**
- [x] Navigate to Sets index
- [x] Observe set cards have **green left border**
- [x] Confirm clear visual difference between Playlists (past) and Sets (future)

---

## ✅ Section 2: Create a New Set (Empty)

### Test 2.1: Create Empty Set via Sets Index

- [x] Navigate to `/dj_sets`
- [x] If no sets exist, should see: "No sets yet. Start building your first set!"
- [x] Click "Create New Set"
- [x] Fill in form:
  - Name: "Weekend House Set"
  - Description: "Deep house tracks for Friday night"
  - ISSUE #1 (RESOLVED) => 0 / 500 characters is static, nothing changes as I type characters into the text area
- [x] Click "Create Set"
- [x] Should redirect to set show page
- [x] Should see success message: "Weekend House Set created successfully"
- ISSUE #2 (RESOLVED) => The message has "X" link but does not do anything
- [x] Should see empty state: "No tracks in this set yet"

### Test 2.2: View Empty Set Details

- [x] Observe set header shows:
  - Set name and description
  - 0 tracks badge
  - 0:00 duration
  - 0.0 BPM average
  - ISSUE #3 (RESOLVED) => 0.0 BPM average missing
  - "Updated X ago" timestamp
- [x] Harmonic score section should not show (no tracks = no transitions)
- ISSUE #4 (RESOLVED) => 100% Harmonic Flow Score shown
- [x] Should see "Add More Tracks" button

---

## ✅ Section 3: Add Tracks to Set (Method 1: From Tracks Index)

### Test 3.1: Track Selection UI

- [x] Click "Add More Tracks" button from set show page
- [x] Should navigate to `/tracks` page
- [x] Observe checkbox column on the left of track table
- [x] Observe "Select All" checkbox in table header
- [x] Bottom toolbar should be **hidden** (no tracks selected yet)

### Test 3.2: Select Individual Tracks

- [x] Check 3-4 individual track checkboxes
- [x] Bottom toolbar should **appear** at bottom of page
- ISSUE #5 (RESOLVED) => Main app bottom toolbar is on top of track selection toolbar so I cannot clearly see the info and buttons
- [x] Toolbar should show: "X tracks selected"
- [x] Toolbar should have green "Add to Set" button and "Cancel" button

### Test 3.3: Select All Functionality

- [x] Click "Select All" checkbox in header
- [x] All visible track checkboxes should be checked
- ISSUE #5 => (RESOLVED) Main app bottom toolbar is on top of track selection toolbar so I cannot clearly see the info and buttons
- [x] Toolbar count should update to match all tracks on page
- [x] Uncheck "Select All" → All checkboxes should uncheck
- [x] Toolbar should disappear

### Test 3.4: Add Tracks to Existing Set

- [x] Select 3 tracks
- [x] Click "Add to Set" button
- [x] Modal should appear: "Add Tracks to Set"
- [x] Modal should show: "Add **3 track(s)** to:"
- [x] Should see section: "Existing Sets" with list of recent sets
- [x] Should see "Weekend House Set" in the list
- [x] Click "Weekend House Set"
- [x] Should redirect to set show page
- [x] Should see success message: "3 track(s) added"
- [x] Should see 3 tracks in the table

### Test 3.5: Create New Set with Tracks

- [x] Navigate back to `/tracks`
- [x] Select 5 different tracks
- ISSUE #6 (RESOLVED) => bottom bar (main app + track selection) is preventing me to navigate to different pages via pagination. Let's get rid of main app bottom bar and move total track count to top right main toolbar with less text saying "# xxx"
- [x] Click "Add to Set"
- [x] In modal, scroll to "Or Create New Set" section
- [x] Fill in form:
  - Name: "Techno Peak Time"
  - Description: "High energy techno"
  - NEW REQUEST #1 (RESOLVED) => Do we need character count in this modal? are there same validations for new set creation here too?
- [x] Click "Create & Add Tracks"
- ISSUE #7 (RESOLVED) => ERROR CREATING
- [x] Should redirect to new set show page
- [x] Should see 5 tracks in the table
- [x] Tracks should be numbered 1-5 in order of selection

- Issue #8 (RESOLVED) => Persist track selections across pagination

## ✅ Section 4: Set Details & Metadata

### Test 4.1: View Set with Tracks

- [x] Navigate to `/dj_sets`
- [x] Click on "Weekend House Set" card
- [x] Observe set header shows updated metadata:
  - Track count badge (e.g., "3 tracks")
  - Total duration (e.g., "15:30")
  - Average BPM (e.g., "128.5 BPM avg")
  - "Updated X ago"
  - Issue #9 (RESOLVED) => Track addition/removal from set does not change updated X ago

### Test 4.2: Harmonic Analysis Display

- [x] If tracks have keys assigned, should see "Harmonic Flow Analysis" section
- [x] Should show overall harmonic flow score (0-100%)
- [x] Score badge color:
  - Green ≥75%
  - Yellow ≥50%
  - Red <50%
- [x] Should see transition breakdown:
  - 🟢 Perfect: X
  - 🔵 Smooth: X
  - ⚡ Energy: X
  - 🟡 Rough: X

### Test 4.3: Track List with Transitions

- [x] Track table should show all tracks with:
  - Drag handle (grip icon) on left
  - Track number
  - Track name (clickable → track detail)
  - Artist(s) (clickable → artist page)
  - Key badge (clickable → key page)
  - BPM, Time, Album, Date Added
  - Remove button (X icon)
- [x] Between each track pair, should see transition indicator:
  - 🟢 for Perfect match
  - 🔵 for Smooth transition
  - ⚡ for Energy boost
  - 🟡 for Rough transition
- [x] Hover over transition indicator → Should show tooltip (browser native)

---

## ✅ Section 5: Drag-and-Drop Reordering

### Test 5.1: Reorder Tracks

- [x] Navigate to set with 3+ tracks
- [x] Hover over drag handle (grip icon) → Cursor should change to "grab"
- [x] Click and hold drag handle
- [x] Drag track up or down in the list
- [x] Release to drop in new position
- Issue #10 (RESOLVED) => track numbers don't update
- [x] Track numbers should update (1, 2, 3, etc.)
- Issue #11 (RESOLVED) => transition indicators don't update
- [x] Transition indicators should update
- Issue #12 (RESOLVED) => harmonic score badge don't update
- [x] Harmonic score badge should update (if applicable)

### Test 5.2: Verify Order Persists

- [x] After reordering, refresh the page
- [x] Track order should remain as you set it
- [x] Navigate away and back to set
- [x] Order should still be saved

---

## ✅ Section 6: Edit Set Metadata

### Test 6.1: Edit Set Name & Description

- [x] On set show page, click "Edit" button
- [x] Should navigate to edit form
- [x] Change name to "Weekend House Set (Updated)"
- [x] Change description
- [x] Click "Update Dj set"
- [x] Should redirect to set show page
- [x] Should see success message: "Set updated"
- [x] Should see updated name and description

### Test 6.2: Validation - Duplicate Name

- [x] Create two sets with different names
- [x] Try to edit one set to have the same name as the other
- [x] Should see error: "Name has already been taken"
- Issue #13 (RESOLVED) => 1 error prohibited this set from being saved: generic message above specific error looks ugly. let's remove those, only leave specific errors. Also, there is no X button to dismiss error(s)

### Test 6.3: Validation - Empty Name

- [x] Try to edit set with empty name
- [x] Should see error: "Name can't be blank"
- Non-Issue #1 => we cannot reach here as HTML form validation does not let me submit, which is good.

---

## ✅ Section 7: Remove Tracks from Set

### Test 7.1: Remove Individual Track

- [x] Navigate to set with multiple tracks
- [x] Click "X" button on one track
- [x] Should see confirmation: "Remove this track?"
- [x] Confirm removal
- [x] Track should disappear from list
- [x] Track numbers should update (re-sequence)
- [x] Success message: "Track removed"
- [x] Harmonic score should update
- Issue #14 (RESOLVED) => Track numbers looks weird (i.e., 3, 6, 10, 21) until I reorder by drag and drop they become normal (i.e., 1, 2, 3, 4)

### Test 7.2: Verify Track Still Exists in Database

- [x] Navigate to `/tracks`
- [x] Search for the track you just removed
- [x] Track should still exist in database
- [x] Track should no longer show this set in "Playlists" column (or should show other sets if in multiple)
- Non-Issue #2 => We don't show Sets in Playlists column anyway
---

## ✅ Section 8: Duplicate a Set

### Test 8.1: Duplicate Set

- [x] Navigate to any set show page
- [x] Click "Duplicate" button
- [x] Should redirect to new set
- [x] New set name should be "[Original Name] (Copy)"
- [x] Should have same description as original
- [x] Should have same tracks in same order
- [x] Success message: "Duplicated as [New Set Name]"

### Test 8.2: Edit Duplicated Set

- [x] On the duplicated set, change name to something unique
- [x] Add or remove tracks
- [x] Reorder tracks
- [x] Navigate back to original set
- [x] Original set should be unchanged
- New Request #2 (RESOLVED) => No way to remove multiple tracks at the same time
---

## ✅ Section 9: Export Set to File

### Test 9.1: Export Set

- [x] Navigate to set with tracks
- [x] Click "Export" button (download icon)
- [x] Should trigger file download
- [x] File should be named: `[set-name]_[timestamp].txt`
- [x] Open downloaded file in text editor

### Test 9.2: Verify Export Format

- [x] File should be tab-delimited
- [x] First line should be headers: `# Track Title Artist BPM Key Time Album Date Added`
- [x] Each subsequent line should be a track
- [x] Verify data matches what's in the set
- [x] Track order should match set order (1, 2, 3...)

### Test 9.3: Re-import Exported File (Optional)

- [x] Navigate to `/playlists/new`
- [x] Upload the exported file
- [x] Choose a cover art image
- [x] Import should succeed
- [x] New playlist should have same tracks in same order
- [x] Verify this creates a **playlist**, not a set

---

## ✅ Section 10: Convert Set to Playlist

### Test 10.1: Convert Without Deleting Original

- [x] Navigate to set show page
- [x] Click "Convert to Playlist" button
- [x] Modal should appear: "Convert to Playlist"
- [x] Name field should be pre-filled with set name
- [x] Upload a cover art image (required)
- [x] Description should be pre-filled (if set has description)
- [x] Leave "Delete original set after conversion" **unchecked**
- [x] Click "Convert to Playlist"
- [x] Should redirect to new playlist show page
- [x] Success message: "Converted to playlist: [Playlist Name]"
- [x] Playlist should have same tracks in same order
- [x] Navigate to `/dj_sets` → Original set should still exist

### Test 10.2: Convert and Delete Original

- [x] Create a new set or use existing one
- [x] Click "Convert to Playlist"
- [x] Fill in name and upload cover art
- [x] **Check** "Delete original set after conversion"
- [x] Click "Convert to Playlist"
- [x] Should redirect to playlist
- [x] Navigate to `/dj_sets` → Original set should be **gone**

### Test 10.3: Validation - Missing Cover Art

- [x] Try to convert without uploading cover art
- [x] Should see error or validation message (cover art required for playlists)

---

## ✅ Section 11: Delete a Set

### Test 11.1: Delete from Set Show Page

- [x] Navigate to set show page
- [x] Click "Delete" button
- [x] Should see confirmation: "Delete [Set Name]?"
- [x] Confirm deletion
- [x] Should redirect to `/dj_sets`
- [x] Success message: "[Set Name] deleted"
- [x] Set should no longer appear in sets list

### Test 11.2: Delete from Sets Index

- [x] Navigate to `/dj_sets`
- [x] Click "x" button on any set card
- [x] Should see confirmation
- [x] Confirm deletion
- [x] Set should disappear from list

### Test 11.3: Verify Tracks Not Deleted

- [x] After deleting set, navigate to `/tracks`
- [x] All tracks that were in the deleted set should still exist
- [x] Tracks should no longer reference the deleted set

---

## ✅ Section 12: Sets Index Functionality

### Test 12.1: View All Sets

- [x] Create 3-4 sets with different names and track counts
- [x] Navigate to `/dj_sets`
- [x] Should see all sets in card grid layout
- [x] Each card should show:
  - Set name
  - Description (truncated)
  - Track count
  - Duration
  - Average BPM
  - Harmonic score badge (if tracks have keys)
  - "Updated X ago"

### Test 12.2: Set Card Actions

- [x] Each card should have quick action buttons:
  - Edit (pencil icon)
  - Export (download icon)
- [x] Click Edit → Should navigate to edit form
- [x] Click Export → Should download file
- [x] Click card itself → Should navigate to set show page

### Test 12.3: Empty State

- [x] Delete all sets
- [x] Navigate to `/dj_sets`
- [x] Should see: "No sets yet. Start building your first set!"
- [x] Should see "Browse Tracks" and "Create New Set" buttons

---

## ✅ Section 13: Integration with Existing Features

### Test 13.1: Search Tracks While Building Sets

- [x] Navigate to `/tracks`
- [x] Use search bar to search for specific track
- [x] Select searched tracks with checkboxes
- [x] Add to set
- [x] Verify search results can be added to sets

### Test 13.2: Harmonic Compatibility Filter

- [x] Navigate to `/tracks`
- [x] Use "Show tracks compatible with" dropdown
- [x] Select a track
- [x] Enable BPM filter
- [x] Results should show compatible tracks
- [x] Select some compatible tracks
- [x] Add to set
- [x] Navigate to set → Should have good harmonic flow score

### Test 13.3: Sorting and Pagination

- [x] On `/tracks`, click column headers to sort
- [x] Select tracks on page 1
- [x] Navigate to page 2
- [x] Selection should persist (or not - verify expected behavior)
- [x] Add tracks from multiple pages to set

### Test 13.4: Track Detail Page Navigation

- [x] From set show page, click on track name
- [x] Should navigate to track detail page
- [x] On track detail, should see "Compatible Tracks" section
- [x] Navigate back using browser back button
- [x] Should return to set show page

---

## ✅ Section 14: Edge Cases & Error Handling

### Test 14.1: Set with No Tracks

- [x] Create empty set
- [x] Navigate to set show page
- [x] Should show: "No tracks in this set yet"
- [x] Should show "Add More Tracks" button
- [x] Harmonic analysis section should not display
- [x] Should not crash or show errors

### Test 14.2: Set with 1 Track

- [x] Add only 1 track to a set
- [x] Harmonic score section should show but with 0 transitions
- [x] Should not crash

### Test 14.3: Tracks Without Keys

- [ ] If any tracks don't have keys assigned
- [ ] Add them to a set
- [ ] Harmonic analysis should handle gracefully
- [ ] Should show "N/A" or skip those transitions
- Non-issue => cannot test as I don't have any track without key

### Test 14.4: Very Long Set Names

- [ ] Try creating set with very long name (100+ characters)
- [ ] Should be truncated in cards on index page
- [ ] Should display fully on show page

### Test 14.5: Special Characters in Names

- [x] Create set with special characters: "House & Techno / Deep Vibes (2025)"
- [x] Should save correctly
- [x] Should export correctly
- [x] Should display correctly everywhere

---
