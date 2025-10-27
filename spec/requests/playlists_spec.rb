# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Playlists", type: :request do
  describe "GET /playlists" do
    let!(:playlists) { create_list(:playlist, 3) }

    it "displays all playlists" do
      get playlists_path
      expect(response).to be_successful
      expect(response.body).to include("Playlists")
    end
  end

  describe "GET /playlists/:id" do
    let(:playlist) { create(:playlist, :with_harmonic_flow) }

    it "displays the playlist with harmonic analysis" do
      get playlist_path(playlist)
      expect(response).to be_successful
      expect(response.body).to include("Harmonic")
    end
  end

  describe "GET /playlists/new" do
    it "returns a successful response" do
      get new_playlist_path
      expect(response).to be_successful
    end
  end

  describe "POST /playlists" do
    let(:file) { fixture_file_upload("valid_playlist.txt", "text/plain") }

    context "with valid file" do
      it "creates a new playlist" do
        expect do
          post playlists_path, params: { playlist: { file: file } }
        end.to change(Playlist, :count).by(1)
      end

      it "redirects to the playlist" do
        post playlists_path, params: { playlist: { file: file } }
        expect(response).to redirect_to(playlist_path(Playlist.last))
      end

      it "sets a success notice" do
        post playlists_path, params: { playlist: { file: file } }
        follow_redirect!
        expect(response.body).to include("Playlist was successfully created")
      end

      it "uses filename as playlist name" do
        post playlists_path, params: { playlist: { file: file } }
        expect(Playlist.last.name).to eq("valid_playlist")
      end
    end

    context "without file" do
      it "does not create a playlist" do
        expect do
          post playlists_path, params: { playlist: {} }
        end.not_to change(Playlist, :count)
      end

      it "renders the new template" do
        post playlists_path, params: { playlist: {} }
        expect(response).to have_http_status(:unprocessable_content)
      end

      it "displays an error message" do
        post playlists_path, params: { playlist: {} }
        expect(response.body).to include("File is required")
      end
    end

    context "with duplicate playlist" do
      before do
        post playlists_path, params: { playlist: { file: file } }
      end

      it "does not create a duplicate" do
        new_file = fixture_file_upload("valid_playlist.txt", "text/plain")
        expect do
          post playlists_path, params: { playlist: { file: new_file } }
        end.not_to change(Playlist, :count)
      end

      it "displays a duplicate error message" do
        new_file = fixture_file_upload("valid_playlist.txt", "text/plain")
        post playlists_path, params: { playlist: { file: new_file } }
        expect(response.body).to include("Duplicate playlist detected")
      end
    end
  end

  describe "DELETE /playlists/:id" do
    let!(:playlist) { create(:playlist, :with_tracks, tracks_count: 2) }

    it "destroys the playlist" do
      expect do
        delete playlist_path(playlist)
      end.to change(Playlist, :count).by(-1)
    end

    it "redirects to playlists index" do
      delete playlist_path(playlist)
      expect(response).to redirect_to(playlists_path)
    end

    it "destroys orphaned tracks" do
      track_ids = playlist.tracks.pluck(:id)
      delete playlist_path(playlist)
      track_ids.each do |track_id|
        expect(Track.exists?(track_id)).to be false
      end
    end

    it "destroys orphaned artists" do
      artist = playlist.tracks.first.artists.first
      delete playlist_path(playlist)
      expect(Artist.exists?(artist.id)).to be false
    end

    it "does not destroy tracks in other playlists" do
      track = playlist.tracks.first
      other_playlist = create(:playlist)
      PlaylistsTrack.create!(playlist: other_playlist, track: track, order: 1)

      initial_count = Track.count
      delete playlist_path(playlist)

      # Only 1 track should be destroyed (the one not in other playlist)
      expect(Track.count).to eq(initial_count - 1)
      expect(Track.exists?(track.id)).to be true
    end
  end

  describe "PATCH /playlists/:id/reorder_tracks" do
    let(:playlist) { create(:playlist) }
    let(:track1) { create(:track) }
    let(:track2) { create(:track) }
    let(:track3) { create(:track) }

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track1, order: 1)
      PlaylistsTrack.create!(playlist: playlist, track: track2, order: 2)
      PlaylistsTrack.create!(playlist: playlist, track: track3, order: 3)
    end

    it "reorders tracks successfully" do
      patch reorder_tracks_playlist_path(playlist), params: {
        order: [
          { id: track3.id, order: 1 },
          { id: track1.id, order: 2 },
          { id: track2.id, order: 3 }
        ]
      }
      expect(response).to have_http_status(:ok)
    end

    it "updates track order" do
      patch reorder_tracks_playlist_path(playlist), params: {
        order: [
          { id: track3.id, order: 1 },
          { id: track1.id, order: 2 },
          { id: track2.id, order: 3 }
        ]
      }
      playlist.reload
      expect(playlist.playlists_tracks.find_by(track: track3).order).to eq(1)
      expect(playlist.playlists_tracks.find_by(track: track1).order).to eq(2)
    end

    it "returns error for non-existent track" do
      patch reorder_tracks_playlist_path(playlist), params: {
        order: [{ id: 999_999, order: 1 }]
      }
      expect(response).to have_http_status(:not_found)
    end
  end
end
