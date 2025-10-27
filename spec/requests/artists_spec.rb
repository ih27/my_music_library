# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artists", type: :request do
  describe "GET /artists" do
    let!(:artists) { create_list(:artist, 3) }

    it "displays all artists" do
      get artists_path
      expect(response).to be_successful
      expect(response.body).to include("Artists")
    end
  end

  describe "GET /artists/:id" do
    let(:artist) { create(:artist, name: "Test Artist") }
    let!(:track_a) { create(:track, name: "Alpha Song", artists: [artist]) }
    let!(:track_z) { create(:track, name: "Zulu Song", artists: [artist]) }
    let!(:playlist) { create(:playlist) }

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track_a, order: 1)
    end

    it "displays the artist details and tracks" do
      get artist_path(artist)
      expect(response).to be_successful
      expect(response.body).to include("Total Tracks")
      expect(response.body).to include("Playlists")
      expect(response.body).to include("Alpha Song")
      expect(response.body).to include("Zulu Song")
    end

    context "with search query" do
      it "accepts search parameters" do
        get artist_path(artist), params: { search: "Song" }
        expect(response).to be_successful
      end
    end

    context "with sorting" do
      it "accepts sorting parameters" do
        get artist_path(artist), params: { sort: "tracks.name", direction: "asc" }
        expect(response).to be_successful
      end
    end
  end
end
