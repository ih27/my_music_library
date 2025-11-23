# Spotify Integration - Requirements Document

## Introduction

This feature integrates the Spotify Web API to automatically enrich track metadata with accurate audio features (energy, danceability, tempo, key) and album artwork. This replaces manual data entry and improves the accuracy of the Playlist Optimizer's energy arc calculations.

## Glossary

- **Spotify Web API**: RESTful API provided by Spotify for accessing music metadata and audio features
- **Audio Features**: Spotify's machine learning-derived metrics for tracks (energy, danceability, valence, etc.)
- **Track Enrichment**: Process of fetching and storing Spotify data for a track in the local database
- **RSpotify**: Ruby gem that wraps the Spotify Web API
- **Client Credentials Flow**: OAuth 2.0 authentication method for server-to-server API requests (no user login required)
- **Rate Limiting**: Spotify API restriction on number of requests per time period
- **Fuzzy Matching**: Algorithm to find best match when exact track name/artist doesn't exist in Spotify

## Requirements

### Requirement 1: Spotify API Authentication

**User Story:** As a system administrator, I want to configure Spotify API credentials so the application can authenticate with Spotify's API.

#### Acceptance Criteria

1. THE System SHALL store Spotify Client ID in environment variable `SPOTIFY_CLIENT_ID`
2. THE System SHALL store Spotify Client Secret in environment variable `SPOTIFY_CLIENT_SECRET`
3. WHEN the application starts, THE System SHALL authenticate with Spotify using Client Credentials Flow
4. IF authentication fails, THEN THE System SHALL log an error and disable Spotify features
5. THE System SHALL display Spotify connection status in the admin interface

---

### Requirement 2: Track Metadata Storage

**User Story:** As a DJ, I want the system to store Spotify metadata for my tracks so I can access accurate audio features and album artwork.

#### Acceptance Criteria

1. THE Track model SHALL store Spotify track ID as a string field
2. THE Track model SHALL store Spotify energy as a decimal field (0.0 to 1.0)
3. THE Track model SHALL store Spotify danceability as a decimal field (0.0 to 1.0)
4. THE Track model SHALL store Spotify valence as a decimal field (0.0 to 1.0)
5. THE Track model SHALL store Spotify preview URL as a string field
6. THE Track model SHALL store Spotify album art URL as a string field
7. THE Track model SHALL store Spotify last enriched timestamp
8. THE Track model SHALL validate that Spotify energy is between 0.0 and 1.0 when present
9. THE Track model SHALL validate that Spotify danceability is between 0.0 and 1.0 when present
10. THE Track model SHALL validate that Spotify valence is between 0.0 and 1.0 when present

---

### Requirement 3: Manual Track Enrichment

**User Story:** As a DJ, when viewing a track detail page, I want to manually enrich the track with Spotify data so I can get accurate audio features for that specific track.

#### Acceptance Criteria

1. WHEN viewing a track without Spotify data, THE System SHALL display an "Enrich from Spotify" button
2. WHEN the user clicks "Enrich from Spotify", THE System SHALL search Spotify API for matching tracks
3. IF multiple matches are found, THEN THE System SHALL display a selection modal with top 5 results
4. WHEN the user selects a match, THE System SHALL fetch audio features from Spotify API
5. THE System SHALL store all Spotify metadata in the track record
6. THE System SHALL display success message with enriched data preview
7. IF no matches are found, THEN THE System SHALL display error message "No Spotify matches found for [Track Name] by [Artist]"
8. IF API request fails, THEN THE System SHALL display error message with retry option
9. WHEN viewing a track with Spotify data, THE System SHALL display "Re-enrich from Spotify" button
10. THE System SHALL display Spotify data badges (energy, danceability, valence) on track detail page

---

### Requirement 4: Automatic Enrichment on Import

**User Story:** As a DJ, when I import a playlist or DJ set from a file, I want the system to automatically enrich all tracks with Spotify data so I don't have to manually enrich each track.

#### Acceptance Criteria

1. WHEN a playlist or DJ set import completes, THE System SHALL queue a background job for Spotify enrichment
2. THE Background Job SHALL process tracks in batches of 10 to respect rate limits
3. FOR each track without Spotify data, THE Background Job SHALL search Spotify API
4. THE Background Job SHALL select the best match based on name similarity and artist match
5. THE Background Job SHALL fetch and store audio features for matched tracks
6. THE Background Job SHALL log enrichment results (success count, failure count, no match count)
7. WHEN enrichment completes, THE System SHALL display notification "Enriched X of Y tracks from Spotify"
8. IF rate limit is exceeded, THEN THE Background Job SHALL pause for 60 seconds and retry
9. THE System SHALL skip tracks that already have Spotify data less than 30 days old
10. THE System SHALL provide option to disable automatic enrichment in settings

---

### Requirement 5: Enhanced Energy Calculation in Optimizer

**User Story:** As a DJ, when I optimize a DJ set, I want the system to use accurate Spotify energy data instead of BPM estimates so the energy arc is more realistic.

#### Acceptance Criteria

1. WHEN calculating track energy, THE PlaylistOptimizerService SHALL use Spotify energy if available
2. IF Spotify energy is not available, THEN THE PlaylistOptimizerService SHALL fall back to BPM-based estimation
3. THE PlaylistOptimizerService SHALL convert Spotify energy (0.0-1.0) to 0-100 scale
4. THE System SHALL display energy source indicator ("Spotify" or "Estimated") in optimization results
5. WHEN displaying optimization results, THE System SHALL show percentage of tracks with Spotify data
6. THE System SHALL log warning if less than 50% of tracks have Spotify energy data

---

### Requirement 6: Spotify Data Display in UI

**User Story:** As a DJ, when browsing tracks, I want to see Spotify audio features so I can make informed decisions about track selection.

#### Acceptance Criteria

1. THE Track detail page SHALL display Spotify energy badge with percentage (0-100%)
2. THE Track detail page SHALL display Spotify danceability badge with percentage (0-100%)
3. THE Track detail page SHALL display Spotify valence badge with label (Sad/Neutral/Happy)
4. THE Track detail page SHALL display Spotify album artwork if available
5. THE Track detail page SHALL display 30-second preview player if preview URL available
6. THE Track index page SHALL display Spotify icon indicator for enriched tracks
7. THE Track index page SHALL support filtering by "Has Spotify Data" checkbox
8. THE Track index page SHALL support sorting by Spotify energy
9. THE Track index page SHALL support sorting by Spotify danceability
10. THE System SHALL display "Last enriched: X days ago" timestamp for Spotify data

---

### Requirement 7: Bulk Enrichment

**User Story:** As a DJ, I want to enrich multiple tracks at once so I can quickly add Spotify data to my entire library.

#### Acceptance Criteria

1. THE Track index page SHALL display "Enrich Selected from Spotify" button when tracks are selected
2. WHEN user clicks bulk enrich button, THE System SHALL queue background job for selected tracks
3. THE Background Job SHALL process tracks in batches respecting rate limits
4. THE System SHALL display progress notification during bulk enrichment
5. WHEN bulk enrichment completes, THE System SHALL display summary "Enriched X of Y tracks"
6. THE System SHALL provide "Enrich All Unenriched Tracks" action in admin interface
7. THE System SHALL estimate completion time based on track count and rate limits
8. THE System SHALL allow cancellation of in-progress bulk enrichment

---

### Requirement 8: Error Handling and Retry Logic

**User Story:** As a system, I want to handle Spotify API errors gracefully so temporary failures don't break the enrichment process.

#### Acceptance Criteria

1. WHEN Spotify API returns 429 (rate limit), THE System SHALL wait for retry-after duration and retry
2. WHEN Spotify API returns 401 (unauthorized), THE System SHALL re-authenticate and retry once
3. WHEN Spotify API returns 404 (not found), THE System SHALL log "no match" and skip track
4. WHEN Spotify API returns 500 (server error), THE System SHALL retry up to 3 times with exponential backoff
5. WHEN network timeout occurs, THE System SHALL retry up to 2 times
6. THE System SHALL log all API errors with track context for debugging
7. THE System SHALL display user-friendly error messages without exposing API details
8. THE System SHALL track failed enrichment attempts and provide manual retry option

---

### Requirement 9: Rate Limit Management

**User Story:** As a system, I want to respect Spotify API rate limits so the application doesn't get blocked.

#### Acceptance Criteria

1. THE System SHALL track API request count per hour
2. WHEN approaching rate limit (90% of quota), THE System SHALL slow down requests
3. THE System SHALL display rate limit status in admin interface
4. THE System SHALL prioritize manual enrichment requests over automatic background jobs
5. THE System SHALL batch multiple track lookups into single API request when possible
6. THE System SHALL cache Spotify search results for 24 hours to reduce duplicate requests
7. THE System SHALL implement exponential backoff when rate limited
8. THE System SHALL log rate limit events for monitoring

---

### Requirement 10: Data Refresh Strategy

**User Story:** As a DJ, I want outdated Spotify data to be refreshed periodically so my track metadata stays current.

#### Acceptance Criteria

1. THE System SHALL consider Spotify data stale after 90 days
2. THE System SHALL display "Spotify data may be outdated" warning for stale data
3. THE System SHALL provide "Refresh Spotify Data" button for tracks with stale data
4. THE System SHALL queue weekly background job to refresh stale data for active tracks
5. THE System SHALL prioritize refreshing tracks used in recent DJ sets
6. THE System SHALL skip refresh for tracks not used in past 6 months
7. THE System SHALL log refresh operations for audit trail

---

## API Credentials Setup Instructions

### Step 1: Create Spotify Developer Account

1. Go to https://developer.spotify.com/dashboard
2. Log in with your Spotify account (or create one)
3. Click "Create an App"
4. Fill in:
   - **App Name**: "Music Archive DJ App" (or your app name)
   - **App Description**: "DJ playlist management with harmonic mixing analysis"
   - **Redirect URI**: Leave blank (not needed for Client Credentials flow)
5. Accept terms and click "Create"

### Step 2: Get API Credentials

1. On your app dashboard, you'll see:
   - **Client ID**: Copy this value
   - **Client Secret**: Click "Show Client Secret" and copy this value
2. Keep these values secure - treat them like passwords

### Step 3: Configure Environment Variables

Add to your `.env` file (create if it doesn't exist):

```bash
SPOTIFY_CLIENT_ID=your_client_id_here
SPOTIFY_CLIENT_SECRET=your_client_secret_here
```

**IMPORTANT**: Add `.env` to `.gitignore` to avoid committing secrets to version control.

### Step 4: Verify Configuration

After implementation, the system will display Spotify connection status in the admin interface. You should see:
- ✅ Connected to Spotify API
- Rate limit: X requests remaining this hour
- Last authenticated: [timestamp]

---

## Out of Scope (Future Enhancements)

- User-specific Spotify OAuth (accessing user's playlists)
- Importing Spotify playlists directly
- Exporting DJ Sets to Spotify playlists
- Real-time Spotify playback integration
- Spotify track recommendations based on DJ sets
- Genre auto-tagging from Spotify artist data
