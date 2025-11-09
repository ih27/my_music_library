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

    it "does not destroy tracks (tracks are permanent library)" do
      track_ids = playlist.tracks.pluck(:id)
      initial_track_count = Track.count
      delete playlist_path(playlist)

      # Tracks should remain in database
      expect(Track.count).to eq(initial_track_count)
      track_ids.each do |track_id|
        expect(Track.exists?(track_id)).to be true
      end
    end

    it "does not destroy artists (artists are permanent library)" do
      artist = playlist.tracks.first.artists.first
      initial_artist_count = Artist.count
      delete playlist_path(playlist)

      # Artists should remain in database
      expect(Artist.count).to eq(initial_artist_count)
      expect(Artist.exists?(artist.id)).to be true
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

  describe "POST /playlists/:id/convert_to_dj_set" do
    let(:playlist) { create(:playlist, :with_tracks, name: "Summer Vibes", tracks_count: 5) }

    it "creates a new DJ Set" do
      expect do
        post convert_to_dj_set_playlist_path(playlist)
      end.to change(DjSet, :count).by(1)
    end

    it "redirects to the new DJ Set" do
      post convert_to_dj_set_playlist_path(playlist)
      expect(response).to redirect_to(dj_set_path(DjSet.last))
    end

    it "sets a success notice" do
      post convert_to_dj_set_playlist_path(playlist)
      follow_redirect!
      expect(response.body).to include("Converted to DJ Set")
    end

    it "uses default name with suffix" do
      post convert_to_dj_set_playlist_path(playlist)
      expect(DjSet.last.name).to eq("Summer Vibes (DJ Set)")
    end

    it "accepts custom name parameter" do
      post convert_to_dj_set_playlist_path(playlist), params: { name: "Custom Name" }
      expect(DjSet.last.name).to eq("Custom Name")
    end

    it "does not delete the original playlist" do
      playlist # Force creation
      expect do
        post convert_to_dj_set_playlist_path(playlist)
      end.not_to change(Playlist, :count)
      expect(Playlist.exists?(playlist.id)).to be true
    end

    it "copies all tracks to the DJ Set" do
      post convert_to_dj_set_playlist_path(playlist)
      dj_set = DjSet.last
      expect(dj_set.tracks.count).to eq(playlist.tracks.count)
      expect(dj_set.tracks.pluck(:id)).to match_array(playlist.tracks.pluck(:id))
    end

    it "maintains track order" do
      post convert_to_dj_set_playlist_path(playlist)
      dj_set = DjSet.last
      playlist.playlists_tracks.order(:order).each_with_index do |pt, index|
        dj_set_track = dj_set.dj_sets_tracks.order(:order)[index]
        expect(dj_set_track.track_id).to eq(pt.track_id)
        expect(dj_set_track.order).to eq(pt.order)
      end
    end

    context "when conversion fails" do
      before do
        # Create a DJ Set with the expected default name
        create(:dj_set, name: "Summer Vibes (DJ Set)")
      end

      it "redirects back to playlist" do
        post convert_to_dj_set_playlist_path(playlist)
        expect(response).to redirect_to(playlist_path(playlist))
      end

      it "sets an error alert" do
        post convert_to_dj_set_playlist_path(playlist)
        follow_redirect!
        expect(response.body).to include("Error converting")
      end

      it "does not create a DJ Set" do
        expect do
          post convert_to_dj_set_playlist_path(playlist)
        end.not_to change(DjSet, :count)
      end
    end
  end
end
