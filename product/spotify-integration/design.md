# Spotify Integration - Design Document

## Overview

This document outlines the technical design for integrating Spotify Web API to enrich track metadata with accurate audio features. The integration uses the RSpotify gem for API communication and implements a service-oriented architecture for enrichment operations.

## Architecture

### High-Level Flow

```
┌─────────────────┐
│   User Action   │
│ (Manual/Import) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Controller     │
│  (Tracks/Jobs)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│ SpotifyService  │
│ (Search/Fetch)  │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Spotify API    │
│  (RSpotify gem) │
└────────┬────────┘
         │
         ▼
┌─────────────────┐
│  Track Model    │
│ (Store metadata)│
└─────────────────┘
```

### Component Diagram

```
┌──────────────────────────────────────────────────────────┐
│                     Presentation Layer                    │
├──────────────────────────────────────────────────────────┤
│  tracks/show.html.erb  │  tracks/index.html.erb          │
│  - Enrich button       │  - Bulk enrich button           │
│  - Spotify badges      │  - Filter by Spotify data       │
│  - Preview player      │  - Sort by energy/danceability  │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                    Controller Layer                       │
├──────────────────────────────────────────────────────────┤
│  TracksController                                         │
│  - enrich_from_spotify (manual enrichment)               │
│  - bulk_enrich (multiple tracks)                         │
│  - select_spotify_match (disambiguation)                 │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                     Service Layer                         │
├──────────────────────────────────────────────────────────┤
│  SpotifyEnrichmentService                                │
│  - enrich_track(track)                                   │
│  - search_spotify(track_name, artist_name)               │
│  - fetch_audio_features(spotify_id)                      │
│  - select_best_match(results, track)                     │
│                                                           │
│  SpotifyAuthService                                      │
│  - authenticate                                          │
│  - refresh_token                                         │
│  - check_connection                                      │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                    Background Jobs                        │
├──────────────────────────────────────────────────────────┤
│  SpotifyEnrichmentJob                                    │
│  - perform(track_ids, options)                           │
│  - batch processing with rate limiting                   │
│  - retry logic for failures                              │
│                                                           │
│  SpotifyBulkEnrichmentJob                                │
│  - perform(track_ids)                                    │
│  - progress tracking                                     │
│  - cancellation support                                  │
└──────────────────────────────────────────────────────────┘
                           │
                           ▼
┌──────────────────────────────────────────────────────────┐
│                      Data Layer                           │
├──────────────────────────────────────────────────────────┤
│  Track Model                                             │
│  - spotify_id, spotify_energy, spotify_danceability      │
│  - spotify_valence, spotify_preview_url                  │
│  - spotify_album_art_url, spotify_enriched_at            │
│  - enriched_from_spotify?, stale_spotify_data?           │
│  - energy_for_optimizer (uses Spotify or fallback)       │
└──────────────────────────────────────────────────────────┘
```

## Components and Interfaces

### 1. Track Model Extensions

**File:** `app/models/track.rb`

**New Fields:**
```ruby
# Migration: AddSpotifyFieldsToTracks
add_column :tracks, :spotify_id, :string
add_column :tracks, :spotify_energy, :decimal, precision: 5, scale: 4
add_column :tracks, :spotify_danceability, :decimal, precision: 5, scale: 4
add_column :tracks, :spotify_valence, :decimal, precision: 5, scale: 4
add_column :tracks, :spotify_preview_url, :string
add_column :tracks, :spotify_album_art_url, :string
add_column :tracks, :spotify_enriched_at, :datetime

add_index :tracks, :spotify_id, unique: true
add_index :tracks, :spotify_enriched_at
```

**New Methods:**
```ruby
class Track < ApplicationRecord
  # Validations
  validates :spotify_energy, 
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  validates :spotify_danceability,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  validates :spotify_valence,
            numericality: { greater_than_or_equal_to: 0, less_than_or_equal_to: 1 },
            allow_nil: true
  validates :spotify_id, uniqueness: true, allow_nil: true

  # Scopes
  scope :with_spotify_data, -> { where.not(spotify_id: nil) }
  scope :without_spotify_data, -> { where(spotify_id: nil) }
  scope :with_stale_spotify_data, -> { 
    where('spotify_enriched_at < ?', 90.days.ago) 
  }

  # Query methods
  def enriched_from_spotify?
    spotify_id.present?
  end

  def stale_spotify_data?
    enriched_from_spotify? && spotify_enriched_at < 90.days.ago
  end

  # Energy calculation for optimizer (uses Spotify if available)
  def energy_for_optimizer
    if spotify_energy.present?
      (spotify_energy * 100).round(2)
    else
      # Fallback to BPM estimation
      estimate_energy_from_bpm
    end
  end

  # Display helpers
  def spotify_energy_percentage
    return nil unless spotify_energy
    (spotify_energy * 100).round(0)
  end

  def spotify_danceability_percentage
    return nil unless spotify_danceability
    (spotify_danceability * 100).round(0)
  end

  def spotify_valence_label
    return nil unless spotify_valence
    case spotify_valence
    when 0.0..0.33 then "Sad"
    when 0.33..0.66 then "Neutral"
    else "Happy"
    end
  end

  private

  def estimate_energy_from_bpm
    return 50 if bpm.nil?
    bpm_energy = ((bpm - 80) / 80.0 * 80).clamp(0, 80)
    key_mode_bonus = key&.name&.end_with?('B') ? 20 : 0
    (bpm_energy + key_mode_bonus).clamp(0, 100)
  end
end
```

### 2. SpotifyEnrichmentService

**File:** `app/services/spotify_enrichment_service.rb`

**Purpose:** Core service for searching Spotify and enriching tracks

**Interface:**
```ruby
class SpotifyEnrichmentService
  class SpotifyError < StandardError; end
  class RateLimitError < SpotifyError; end
  class AuthenticationError < SpotifyError; end
  class NotFoundError < SpotifyError; end

  # Main enrichment method
  # @param track [Track] Track to enrich
  # @param spotify_id [String] Optional: specific Spotify ID to use
  # @return [Boolean] Success status
  def self.enrich_track(track, spotify_id: nil)
    new(track).enrich(spotify_id: spotify_id)
  end

  # Search for track on Spotify
  # @param track_name [String] Track name
  # @param artist_name [String] Artist name
  # @return [Array<Hash>] Array of search results
  def self.search(track_name, artist_name)
    new(nil).search_spotify(track_name, artist_name)
  end

  def initialize(track)
    @track = track
    @client = RSpotify::Track
  end

  # Enrich track with Spotify data
  def enrich(spotify_id: nil)
    spotify_track = if spotify_id
      fetch_by_id(spotify_id)
    else
      search_and_select_best_match
    end

    return false unless spotify_track

    audio_features = fetch_audio_features(spotify_track.id)
    return false unless audio_features

    update_track_with_spotify_data(spotify_track, audio_features)
    true
  rescue SpotifyError => e
    Rails.logger.error("Spotify enrichment failed for track #{@track.id}: #{e.message}")
    false
  end

  # Search Spotify for matching tracks
  def search_spotify(track_name, artist_name)
    query = build_search_query(track_name, artist_name)
    results = @client.search(query, limit: 5)
    
    format_search_results(results)
  rescue RestClient::TooManyRequests => e
    handle_rate_limit(e)
  rescue RestClient::Unauthorized
    raise AuthenticationError, "Spotify authentication failed"
  end

  private

  def fetch_by_id(spotify_id)
    @client.find(spotify_id)
  rescue RestClient::NotFound
    raise NotFoundError, "Spotify track not found: #{spotify_id}"
  end

  def search_and_select_best_match
    results = search_spotify(@track.name, @track.artists.first&.name)
    return nil if results.empty?

    # Select best match based on similarity
    best_match = select_best_match(results)
    fetch_by_id(best_match[:id])
  end

  def fetch_audio_features(spotify_id)
    track = @client.find(spotify_id)
    track.audio_features
  rescue RestClient::NotFound
    nil
  end

  def update_track_with_spotify_data(spotify_track, audio_features)
    @track.update!(
      spotify_id: spotify_track.id,
      spotify_energy: audio_features.energy,
      spotify_danceability: audio_features.danceability,
      spotify_valence: audio_features.valence,
      spotify_preview_url: spotify_track.preview_url,
      spotify_album_art_url: spotify_track.album.images.first&.dig('url'),
      spotify_enriched_at: Time.current
    )
  end

  def build_search_query(track_name, artist_name)
    query = track_name.to_s
    query += " artist:#{artist_name}" if artist_name.present?
    query
  end

  def format_search_results(results)
    results.map do |track|
      {
        id: track.id,
        name: track.name,
        artists: track.artists.map(&:name).join(', '),
        album: track.album.name,
        preview_url: track.preview_url,
        album_art_url: track.album.images.first&.dig('url'),
        similarity_score: calculate_similarity(track)
      }
    end.sort_by { |r| -r[:similarity_score] }
  end

  def select_best_match(results)
    # Return highest similarity score
    results.first
  end

  def calculate_similarity(spotify_track)
    # Simple similarity: exact name match = 1.0, partial = 0.5
    track_name_match = spotify_track.name.downcase.include?(@track.name.downcase) ? 1.0 : 0.5
    
    artist_name = @track.artists.first&.name&.downcase || ""
    spotify_artists = spotify_track.artists.map(&:name).map(&:downcase).join(' ')
    artist_match = spotify_artists.include?(artist_name) ? 1.0 : 0.5
    
    (track_name_match + artist_match) / 2.0
  end

  def handle_rate_limit(error)
    retry_after = error.response.headers[:retry_after]&.to_i || 60
    raise RateLimitError, "Rate limited. Retry after #{retry_after} seconds"
  end
end
```

### 3. SpotifyAuthService

**File:** `app/services/spotify_auth_service.rb`

**Purpose:** Handle Spotify API authentication

**Interface:**
```ruby
class SpotifyAuthService
  class << self
    def authenticate
      RSpotify.authenticate(
        ENV['SPOTIFY_CLIENT_ID'],
        ENV['SPOTIFY_CLIENT_SECRET']
      )
      @authenticated = true
      @authenticated_at = Time.current
    rescue StandardError => e
      Rails.logger.error("Spotify authentication failed: #{e.message}")
      @authenticated = false
      raise
    end

    def authenticated?
      @authenticated == true
    end

    def connection_status
      return { connected: false, error: "Missing credentials" } unless credentials_present?
      
      authenticate unless authenticated?
      
      {
        connected: authenticated?,
        authenticated_at: @authenticated_at,
        client_id: ENV['SPOTIFY_CLIENT_ID']&.first(8) + "...",
        rate_limit_remaining: rate_limit_remaining
      }
    rescue StandardError => e
      { connected: false, error: e.message }
    end

    def rate_limit_remaining
      # Spotify doesn't expose rate limit in gem, return estimate
      "Unknown (monitoring not implemented)"
    end

    private

    def credentials_present?
      ENV['SPOTIFY_CLIENT_ID'].present? && ENV['SPOTIFY_CLIENT_SECRET'].present?
    end
  end
end
```

### 4. Background Jobs

**File:** `app/jobs/spotify_enrichment_job.rb`

**Purpose:** Enrich tracks in background with rate limiting

```ruby
class SpotifyEnrichmentJob < ApplicationJob
  queue_as :default

  BATCH_SIZE = 10
  RATE_LIMIT_PAUSE = 2.seconds

  def perform(track_ids, options = {})
    tracks = Track.where(id: track_ids).without_spotify_data

    success_count = 0
    failure_count = 0
    no_match_count = 0

    tracks.in_batches(of: BATCH_SIZE) do |batch|
      batch.each do |track|
        result = SpotifyEnrichmentService.enrich_track(track)
        
        if result
          success_count += 1
        elsif track.reload.enriched_from_spotify?
          success_count += 1
        else
          no_match_count += 1
        end
      rescue SpotifyEnrichmentService::RateLimitError => e
        Rails.logger.warn("Rate limited, pausing: #{e.message}")
        sleep 60
        retry
      rescue StandardError => e
        Rails.logger.error("Failed to enrich track #{track.id}: #{e.message}")
        failure_count += 1
      end

      # Pause between batches to respect rate limits
      sleep RATE_LIMIT_PAUSE
    end

    log_results(success_count, failure_count, no_match_count, tracks.count)
  end

  private

  def log_results(success, failure, no_match, total)
    Rails.logger.info(
      "Spotify enrichment complete: #{success}/#{total} enriched, " \
      "#{no_match} no match, #{failure} failed"
    )
  end
end
```

**File:** `app/jobs/spotify_bulk_enrichment_job.rb`

**Purpose:** Bulk enrichment with progress tracking

```ruby
class SpotifyBulkEnrichmentJob < ApplicationJob
  queue_as :default

  def perform(track_ids, user_id: nil)
    @total = track_ids.count
    @processed = 0
    @success = 0

    track_ids.each do |track_id|
      track = Track.find_by(id: track_id)
      next unless track

      if SpotifyEnrichmentService.enrich_track(track)
        @success += 1
      end

      @processed += 1
      broadcast_progress(user_id) if user_id
    rescue StandardError => e
      Rails.logger.error("Bulk enrichment error for track #{track_id}: #{e.message}")
    end

    broadcast_complete(user_id) if user_id
  end

  private

  def broadcast_progress(user_id)
    # ActionCable broadcast for real-time progress (optional)
    # ActionCable.server.broadcast("user_#{user_id}", {
    #   type: 'enrichment_progress',
    #   processed: @processed,
    #   total: @total,
    #   success: @success
    # })
  end

  def broadcast_complete(user_id)
    # ActionCable.server.broadcast("user_#{user_id}", {
    #   type: 'enrichment_complete',
    #   success: @success,
    #   total: @total
    # })
  end
end
```

### 5. Controller Actions

**File:** `app/controllers/tracks_controller.rb`

**New Actions:**
```ruby
class TracksController < ApplicationController
  # GET /tracks/:id/spotify_search
  def spotify_search
    @track = Track.find(params[:id])
    @results = SpotifyEnrichmentService.search(
      @track.name,
      @track.artists.first&.name
    )

    render json: @results
  rescue StandardError => e
    render json: { error: e.message }, status: :unprocessable_entity
  end

  # POST /tracks/:id/enrich_from_spotify
  def enrich_from_spotify
    @track = Track.find(params[:id])
    spotify_id = params[:spotify_id] # Optional: user-selected match

    if SpotifyEnrichmentService.enrich_track(@track, spotify_id: spotify_id)
      redirect_to @track, notice: "Track enriched from Spotify successfully!"
    else
      redirect_to @track, alert: "Failed to enrich track from Spotify. No matches found."
    end
  rescue StandardError => e
    redirect_to @track, alert: "Error: #{e.message}"
  end

  # POST /tracks/bulk_enrich
  def bulk_enrich
    track_ids = params[:track_ids].reject(&:blank?)
    
    SpotifyBulkEnrichmentJob.perform_later(track_ids, user_id: current_user&.id)
    
    redirect_to tracks_path, 
                notice: "Enriching #{track_ids.count} tracks in background. This may take a few minutes."
  end
end
```

### 6. PlaylistOptimizerService Integration

**File:** `app/services/playlist_optimizer_service.rb`

**Update:**
```ruby
# Replace estimate_track_energy method
def estimate_track_energy(track)
  # Use Spotify data if available
  return track.energy_for_optimizer if track.enriched_from_spotify?
  
  # Fallback to BPM estimation (existing logic)
  return 50 if track.bpm.nil?
  bpm_energy = ((track.bpm - 80) / 80.0 * 80).clamp(0, 80)
  key_mode_bonus = track.key&.name&.end_with?('B') ? 20 : 0
  (bpm_energy + key_mode_bonus).clamp(0, 100)
end
```

## Data Models

### Track Model Schema Changes

```ruby
# db/migrate/YYYYMMDDHHMMSS_add_spotify_fields_to_tracks.rb
class AddSpotifyFieldsToTracks < ActiveRecord::Migration[8.1]
  def change
    add_column :tracks, :spotify_id, :string
    add_column :tracks, :spotify_energy, :decimal, precision: 5, scale: 4
    add_column :tracks, :spotify_danceability, :decimal, precision: 5, scale: 4
    add_column :tracks, :spotify_valence, :decimal, precision: 5, scale: 4
    add_column :tracks, :spotify_preview_url, :string
    add_column :tracks, :spotify_album_art_url, :string
    add_column :tracks, :spotify_enriched_at, :datetime

    add_index :tracks, :spotify_id, unique: true
    add_index :tracks, :spotify_enriched_at
  end
end
```

## Error Handling

### Error Hierarchy

```ruby
SpotifyEnrichmentService::SpotifyError
  ├── RateLimitError (429 responses)
  ├── AuthenticationError (401 responses)
  └── NotFoundError (404 responses)
```

### Retry Strategy

| Error Type | Retry Count | Backoff | Action |
|------------|-------------|---------|--------|
| Rate Limit (429) | Unlimited | Wait retry-after header | Pause and retry |
| Auth Error (401) | 1 | Immediate | Re-authenticate once |
| Not Found (404) | 0 | N/A | Log and skip |
| Server Error (500) | 3 | Exponential (2s, 4s, 8s) | Retry with backoff |
| Network Timeout | 2 | Linear (5s, 10s) | Retry with delay |

## Testing Strategy

### Unit Tests

**SpotifyEnrichmentService:**
- Search returns formatted results
- Best match selection algorithm
- Audio features fetching
- Error handling for each error type
- Retry logic

**Track Model:**
- Validations for Spotify fields
- Scopes (with/without Spotify data)
- Helper methods (energy_for_optimizer, stale_spotify_data?)
- Display helpers (percentages, labels)

**SpotifyAuthService:**
- Authentication success/failure
- Connection status reporting
- Missing credentials handling

### Integration Tests

**Enrichment Flow:**
- Manual enrichment from track detail page
- Automatic enrichment after import
- Bulk enrichment from track index
- Disambiguation when multiple matches

**Optimizer Integration:**
- Uses Spotify energy when available
- Falls back to BPM estimation
- Displays energy source in results

### Request Specs

**TracksController:**
- GET /tracks/:id/spotify_search returns results
- POST /tracks/:id/enrich_from_spotify updates track
- POST /tracks/bulk_enrich queues job
- Error responses for API failures

### Performance Tests

- Batch processing respects rate limits
- Background jobs complete within expected time
- No N+1 queries during bulk operations
- Cache effectiveness for repeated searches

## Security Considerations

1. **API Credentials:**
   - Store in environment variables (never commit)
   - Use Rails credentials for production
   - Rotate credentials periodically

2. **Rate Limiting:**
   - Implement request throttling
   - Monitor API usage
   - Graceful degradation when limited

3. **Data Validation:**
   - Validate all Spotify data before storage
   - Sanitize URLs before display
   - Prevent SQL injection in search queries

4. **Error Messages:**
   - Don't expose API credentials in errors
   - Log detailed errors server-side only
   - Show user-friendly messages in UI

## Performance Optimization

1. **Caching:**
   - Cache search results for 24 hours
   - Cache audio features indefinitely (keyed by spotify_id)
   - Use Redis for distributed caching

2. **Batch Processing:**
   - Process tracks in batches of 10
   - Pause between batches (2 seconds)
   - Use background jobs for bulk operations

3. **Database:**
   - Index spotify_id for fast lookups
   - Index spotify_enriched_at for stale data queries
   - Use eager loading to avoid N+1 queries

4. **API Optimization:**
   - Batch multiple track lookups when possible
   - Reuse authentication tokens
   - Implement circuit breaker for repeated failures

## Monitoring and Logging

### Metrics to Track

- Enrichment success rate
- API response times
- Rate limit hits per hour
- Failed enrichment reasons
- Tracks enriched per day

### Log Events

```ruby
# Success
Rails.logger.info("Spotify: Enriched track #{track.id} (#{track.name})")

# Rate limit
Rails.logger.warn("Spotify: Rate limited, pausing for #{retry_after}s")

# Error
Rails.logger.error("Spotify: Failed to enrich track #{track.id}: #{error.message}")

# Batch complete
Rails.logger.info("Spotify: Batch complete - #{success}/#{total} enriched")
```

## Deployment Checklist

- [ ] Add RSpotify gem to Gemfile
- [ ] Run database migration
- [ ] Set environment variables (SPOTIFY_CLIENT_ID, SPOTIFY_CLIENT_SECRET)
- [ ] Test authentication in Rails console
- [ ] Deploy to staging
- [ ] Verify Spotify connection in admin UI
- [ ] Test manual enrichment
- [ ] Test automatic enrichment on import
- [ ] Monitor logs for errors
- [ ] Deploy to production
- [ ] Update documentation
