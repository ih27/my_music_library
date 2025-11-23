# Spotify Integration - Implementation Tasks

## Overview

This task list implements Spotify API integration for automatic track enrichment with audio features (energy, danceability, valence) and album artwork. Tasks are organized in sequential order with clear dependencies.

---

## Phase 1: Foundation & Setup

- [ ] 1. Set up Spotify API credentials and authentication
  - Add `rspotify` gem to Gemfile (version ~> 2.11)
  - Run `bundle install`
  - Create `.env` file with placeholder credentials
  - Add `.env` to `.gitignore`
  - Create `config/initializers/spotify.rb` for RSpotify configuration
  - Test authentication in Rails console with dummy credentials
  - _Requirements: 1.1, 1.2, 1.3_

- [ ] 2. Create database migration for Spotify fields
  - Generate migration: `rails g migration AddSpotifyFieldsToTracks`
  - Add columns: spotify_id, spotify_energy, spotify_danceability, spotify_valence, spotify_preview_url, spotify_album_art_url, spotify_enriched_at
  - Add indexes on spotify_id (unique) and spotify_enriched_at
  - Run migration: `rails db:migrate`
  - Verify schema in `db/schema.rb`
  - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7_

- [ ] 3. Update Track model with Spotify fields and validations
  - Add validations for spotify_energy, spotify_danceability, spotify_valence (0.0-1.0 range)
  - Add validation for spotify_id uniqueness
  - Add scopes: `with_spotify_data`, `without_spotify_data`, `with_stale_spotify_data`
  - Add query methods: `enriched_from_spotify?`, `stale_spotify_data?`
  - Add display helpers: `spotify_energy_percentage`, `spotify_danceability_percentage`, `spotify_valence_label`
  - Add `energy_for_optimizer` method (uses Spotify data or falls back to BPM estimation)
  - _Requirements: 2.8, 2.9, 2.10_

---

## Phase 2: Core Enrichment Service

- [ ] 4. Create SpotifyAuthService for API authentication
  - Create `app/services/spotify_auth_service.rb`
  - Implement `authenticate` class method using RSpotify
  - Implement `authenticated?` status check
  - Implement `connection_status` method returning hash with connection details
  - Handle missing credentials gracefully
  - Add error logging for authentication failures
  - _Requirements: 1.3, 1.4_

- [ ] 5. Create SpotifyEnrichmentService for track enrichment
  - Create `app/services/spotify_enrichment_service.rb`
  - Define custom error classes: SpotifyError, RateLimitError, AuthenticationError, NotFoundError
  - Implement `enrich_track(track, spotify_id: nil)` class method
  - Implement `search(track_name, artist_name)` class method
  - Implement private `search_spotify` method using RSpotify::Track.search
  - Implement private `fetch_audio_features` method
  - Implement private `select_best_match` using similarity scoring
  - Implement private `update_track_with_spotify_data` method
  - Add retry logic for rate limits (429 responses)
  - Add error handling for 401, 404, 500 responses
  - _Requirements: 3.2, 3.3, 3.4, 3.5, 8.1, 8.2, 8.3, 8.4_

- [ ] 6. Implement similarity scoring algorithm
  - Add `calculate_similarity` private method to SpotifyEnrichmentService
  - Score based on track name match (exact vs partial)
  - Score based on artist name match
  - Return combined similarity score (0.0-1.0)
  - Sort search results by similarity score
  - _Requirements: 3.3_

---

## Phase 3: Manual Enrichment UI

- [ ] 7. Add manual enrichment button to track detail page
  - Update `app/views/tracks/show.html.erb`
  - Add "Enrich from Spotify" button (visible when no Spotify data)
  - Add "Re-enrich from Spotify" button (visible when Spotify data exists)
  - Style buttons with Bootstrap classes
  - Add loading state indicator
  - _Requirements: 3.1, 3.9_

- [ ] 8. Create controller actions for manual enrichment
  - Add `spotify_search` action to TracksController (GET /tracks/:id/spotify_search)
  - Add `enrich_from_spotify` action to TracksController (POST /tracks/:id/enrich_from_spotify)
  - Handle spotify_id parameter for user-selected match
  - Add success/error flash messages
  - Add routes in `config/routes.rb`
  - _Requirements: 3.2, 3.6, 3.7, 3.8_

- [ ] 9. Create Spotify match selection modal
  - Create partial `app/views/tracks/_spotify_match_modal.html.erb`
  - Display top 5 search results with album art, artist, album
  - Add radio buttons for selection
  - Add "Use this match" button
  - Use Stimulus controller for modal interactions
  - Handle AJAX submission
  - _Requirements: 3.3_

- [ ] 10. Display Spotify data badges on track detail page
  - Update `app/views/tracks/show.html.erb`
  - Add energy badge with percentage (0-100%)
  - Add danceability badge with percentage (0-100%)
  - Add valence badge with label (Sad/Neutral/Happy)
  - Display album artwork if available
  - Add 30-second preview player if preview URL available
  - Show "Last enriched: X days ago" timestamp
  - Add "Spotify data may be outdated" warning for stale data
  - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.10, 10.2_

---

## Phase 4: Automatic Enrichment on Import

- [ ] 11. Create SpotifyEnrichmentJob for background processing
  - Create `app/jobs/spotify_enrichment_job.rb`
  - Implement `perform(track_ids, options = {})` method
  - Process tracks in batches of 10
  - Add 2-second pause between batches for rate limiting
  - Implement retry logic for rate limit errors (pause 60 seconds)
  - Log success/failure/no-match counts
  - _Requirements: 4.2, 4.3, 4.4, 4.5, 4.6, 4.7, 8.1, 9.1, 9.2, 9.5_

- [ ] 12. Integrate automatic enrichment into import flow
  - Update `PlaylistImporter` to queue SpotifyEnrichmentJob after import
  - Update `DjSetImporter` to queue SpotifyEnrichmentJob after import
  - Pass imported track IDs to background job
  - Skip tracks that already have Spotify data less than 30 days old
  - Add flash message: "Enriched X of Y tracks from Spotify"
  - _Requirements: 4.1, 4.8, 4.9_

- [ ] 13. Add settings to disable automatic enrichment
  - Create `app/models/setting.rb` (or use existing settings system)
  - Add `auto_enrich_from_spotify` boolean setting (default: true)
  - Check setting before queuing enrichment job
  - Add toggle in admin/settings UI
  - _Requirements: 4.10_

---

## Phase 5: Bulk Enrichment

- [ ] 14. Add bulk enrichment UI to tracks index
  - Update `app/views/tracks/index.html.erb`
  - Add "Enrich Selected from Spotify" button (appears when tracks selected)
  - Integrate with existing Set Builder selection UI
  - Add loading indicator during bulk operation
  - _Requirements: 7.1_

- [ ] 15. Create SpotifyBulkEnrichmentJob with progress tracking
  - Create `app/jobs/spotify_bulk_enrichment_job.rb`
  - Implement `perform(track_ids, user_id: nil)` method
  - Track progress: processed count, success count
  - Add optional ActionCable broadcast for real-time progress (commented out for now)
  - Log completion summary
  - _Requirements: 7.2, 7.3, 7.4, 7.7_

- [ ] 16. Add bulk enrichment controller action
  - Add `bulk_enrich` action to TracksController (POST /tracks/bulk_enrich)
  - Accept track_ids parameter
  - Queue SpotifyBulkEnrichmentJob
  - Display flash message: "Enriching X tracks in background"
  - Add route in `config/routes.rb`
  - _Requirements: 7.5_

- [ ] 17. Add "Enrich All Unenriched Tracks" admin action
  - Create admin controller or add to existing admin area
  - Add action to enrich all tracks without Spotify data
  - Display estimated completion time based on track count
  - Add confirmation modal
  - Queue SpotifyBulkEnrichmentJob with all unenriched track IDs
  - _Requirements: 7.6, 7.7_

---

## Phase 6: Optimizer Integration

- [ ] 18. Update PlaylistOptimizerService to use Spotify energy
  - Modify `estimate_track_energy` method in `app/services/playlist_optimizer_service.rb`
  - Use `track.energy_for_optimizer` instead of direct BPM calculation
  - This automatically uses Spotify data when available, falls back to BPM
  - Add energy source tracking ("Spotify" vs "Estimated")
  - _Requirements: 5.1, 5.2, 5.3_

- [ ] 19. Display energy source in optimization results
  - Update `app/views/dj_sets/show.html.erb` optimization results section
  - Show percentage of tracks with Spotify data
  - Add indicator: "Energy calculated from: X% Spotify, Y% Estimated"
  - Display warning if less than 50% have Spotify data
  - _Requirements: 5.4, 5.5, 5.6_

---

## Phase 7: Enhanced Track Index

- [ ] 20. Add Spotify data indicators to track index
  - Update `app/views/tracks/index.html.erb`
  - Add Spotify icon indicator for enriched tracks
  - Show energy/danceability badges in track rows (optional, space permitting)
  - _Requirements: 6.6_

- [ ] 21. Add filtering by Spotify data
  - Add "Has Spotify Data" checkbox filter to tracks index
  - Update TracksController#index to filter by `with_spotify_data` scope
  - Preserve filter across pagination
  - _Requirements: 6.7_

- [ ] 22. Add sorting by Spotify metrics
  - Add sort options: "Energy (Spotify)", "Danceability (Spotify)"
  - Update TracksController#index to support sorting by spotify_energy, spotify_danceability
  - Handle null values (tracks without Spotify data appear last)
  - _Requirements: 6.8, 6.9_

---

## Phase 8: Error Handling & Rate Limiting

- [ ] 23. Implement comprehensive error handling
  - Add error handling for all Spotify API error types in SpotifyEnrichmentService
  - Implement exponential backoff for 500 errors (2s, 4s, 8s)
  - Implement linear backoff for network timeouts (5s, 10s)
  - Log all errors with track context
  - Display user-friendly error messages (no API details exposed)
  - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6, 8.7_

- [ ] 24. Add manual retry option for failed enrichments
  - Track failed enrichment attempts in database (optional: add failed_enrichment_count column)
  - Display "Retry Enrichment" button for tracks with failed attempts
  - Clear failure count on successful enrichment
  - _Requirements: 8.8_

- [ ] 25. Implement rate limit management
  - Track API request count per hour (in-memory or Redis)
  - Slow down requests when approaching 90% of quota
  - Display rate limit status in admin interface
  - Prioritize manual requests over background jobs
  - Implement request batching where possible
  - Cache search results for 24 hours
  - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5, 9.6, 9.7, 9.8_

---

## Phase 9: Data Refresh Strategy

- [ ] 26. Implement stale data detection and refresh
  - Use existing `stale_spotify_data?` method (data older than 90 days)
  - Display "Spotify data may be outdated" warning on track detail page
  - Add "Refresh Spotify Data" button for stale tracks
  - _Requirements: 10.1, 10.2, 10.3_

- [ ] 27. Create weekly refresh background job
  - Create `app/jobs/spotify_refresh_stale_data_job.rb`
  - Schedule weekly via cron or whenever gem
  - Refresh stale data for tracks used in recent DJ sets (last 6 months)
  - Skip tracks not used in past 6 months
  - Log refresh operations
  - _Requirements: 10.4, 10.5, 10.6, 10.7_

---

## Phase 10: Admin Interface

- [ ] 28. Create Spotify connection status page
  - Create admin view showing Spotify connection status
  - Display: Connected status, Client ID (masked), Last authenticated timestamp
  - Display rate limit status (if available)
  - Add "Test Connection" button
  - Add "Re-authenticate" button
  - _Requirements: 1.5_

- [ ] 29. Add Spotify enrichment statistics dashboard
  - Show total tracks with Spotify data
  - Show total tracks without Spotify data
  - Show enrichment success rate (last 7 days)
  - Show average enrichment time
  - Show rate limit usage
  - _Requirements: Monitoring_

---

## Phase 11: Testing

- [ ]* 30. Write unit tests for SpotifyEnrichmentService
  - Test search returns formatted results
  - Test best match selection algorithm
  - Test audio features fetching
  - Test error handling for each error type (429, 401, 404, 500)
  - Test retry logic
  - Mock RSpotify API calls using VCR or WebMock
  - _Requirements: All service requirements_

- [ ]* 31. Write unit tests for Track model
  - Test validations for Spotify fields
  - Test scopes (with_spotify_data, without_spotify_data, with_stale_spotify_data)
  - Test helper methods (enriched_from_spotify?, stale_spotify_data?)
  - Test energy_for_optimizer (Spotify vs fallback)
  - Test display helpers (percentages, labels)
  - _Requirements: 2.8, 2.9, 2.10_

- [ ]* 32. Write unit tests for SpotifyAuthService
  - Test authentication success
  - Test authentication failure
  - Test connection status reporting
  - Test missing credentials handling
  - _Requirements: 1.3, 1.4, 1.5_

- [ ]* 33. Write integration tests for enrichment flow
  - Test manual enrichment from track detail page
  - Test automatic enrichment after import
  - Test bulk enrichment from track index
  - Test disambiguation when multiple matches
  - Use VCR to record real API responses
  - _Requirements: 3.x, 4.x, 7.x_

- [ ]* 34. Write request specs for TracksController
  - Test GET /tracks/:id/spotify_search returns results
  - Test POST /tracks/:id/enrich_from_spotify updates track
  - Test POST /tracks/bulk_enrich queues job
  - Test error responses for API failures
  - _Requirements: 3.x, 7.x_

- [ ]* 35. Write integration tests for optimizer
  - Test optimizer uses Spotify energy when available
  - Test optimizer falls back to BPM estimation
  - Test energy source display in results
  - _Requirements: 5.x_

---

## Phase 12: Documentation & Deployment

- [ ] 36. Update CLAUDE.md with Spotify integration details
  - Document new Track model fields
  - Document SpotifyEnrichmentService usage
  - Document background jobs
  - Document rate limiting strategy
  - Add troubleshooting section
  - _Requirements: All_

- [ ] 37. Create API credentials setup guide
  - Document Spotify Developer account creation
  - Document app creation steps
  - Document credential retrieval
  - Document environment variable setup
  - Add to README or separate SPOTIFY_SETUP.md
  - _Requirements: API Credentials Setup_

- [ ] 38. Run full CI suite and fix any issues
  - Run `bundle exec rubocop -A` to fix style issues
  - Run `bundle exec rspec` to ensure all tests pass
  - Run `bin/ci` to verify full suite
  - Fix any failing tests or linting issues
  - _Requirements: All_

- [ ] 39. Deploy to staging and test
  - Set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET in staging environment
  - Deploy code to staging
  - Test authentication in staging Rails console
  - Test manual enrichment on staging
  - Test automatic enrichment on import
  - Test bulk enrichment
  - Monitor logs for errors
  - _Requirements: All_

- [ ] 40. Deploy to production
  - Set SPOTIFY_CLIENT_ID and SPOTIFY_CLIENT_SECRET in production environment
  - Deploy code to production
  - Verify Spotify connection in admin UI
  - Monitor error logs
  - Test with small batch of tracks first
  - Announce feature to users
  - _Requirements: All_

---

## Notes

- **Dependencies:** Tasks must be completed in order within each phase
- **Testing:** Tasks marked with `*` are optional but recommended for production quality
- **API Credentials:** Required before Phase 2 can be tested (see requirements.md for setup instructions)
- **Rate Limiting:** Be mindful of Spotify API rate limits during development/testing
- **Estimated Time:** 
  - Phase 1-2: 4 hours
  - Phase 3: 4 hours
  - Phase 4: 3 hours
  - Phase 5: 3 hours
  - Phase 6: 2 hours
  - Phase 7: 2 hours
  - Phase 8-9: 3 hours
  - Phase 10: 2 hours
  - Phase 11 (optional): 6 hours
  - Phase 12: 2 hours
  - **Total: ~25 hours (19 hours without optional testing)**
