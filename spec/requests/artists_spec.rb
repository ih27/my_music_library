# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Artists", type: :request do
  describe "GET /artists" do
    let!(:artists) { create_list(:artist, 3) }

    it "returns a successful response" do
      get artists_path
      expect(response).to be_successful
    end

    it "displays all artists" do
      get artists_path
      expect(response).to be_successful
    end

    it "sorts artists by track count and name" do
      artist_with_tracks = create(:artist)
      create(:track, :with_artists, artists: [artist_with_tracks])

      get artists_path
      expect(response).to be_successful
    end
  end

  describe "GET /artists/:id" do
    let(:artist) { create(:artist) }
    let!(:track) { create(:track, artists: [artist]) }
    let!(:playlist) { create(:playlist) }

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track, order: 1)
    end

    it "returns a successful response" do
      get artist_path(artist)
      expect(response).to be_successful
    end

    it "displays the artist details" do
      get artist_path(artist)
      expect(response).to be_successful
      expect(response.body).to include("Total Tracks")
    end

    it "displays artist tracks" do
      get artist_path(artist)
      expect(response).to be_successful
    end

    it "displays playlists containing artist tracks" do
      get artist_path(artist)
      expect(response).to be_successful
      expect(response.body).to include("Playlists")
    end

    context "with search query" do
      it "filters artist tracks by search term" do
        get artist_path(artist), params: { search: "test" }
        expect(response).to be_successful
      end
    end

    context "with sorting" do
      it "sorts tracks by name" do
        get artist_path(artist), params: { sort: "tracks.name", direction: "asc" }
        expect(response).to be_successful
      end
    end
  end
end
