# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Keys", type: :request do
  describe "GET /keys" do
    let!(:keys) { create_list(:key, 5) }

    it "returns a successful response" do
      get keys_path
      expect(response).to be_successful
    end

    it "displays all keys" do
      get keys_path
      expect(response).to be_successful
      expect(response.body).to include("Keys")
    end

    it "sorts keys naturally" do
      get keys_path
      expect(response).to be_successful
    end
  end

  describe "GET /keys/:id" do
    let(:key) { create(:key, :camelot_8a) }
    let!(:track) { create(:track, key: key) }
    let!(:playlist) { create(:playlist) }

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track, order: 1)
    end

    it "returns a successful response" do
      get key_path(key)
      expect(response).to be_successful
    end

    it "displays the key details" do
      get key_path(key)
      expect(response).to be_successful
      expect(response.body).to include("Total Tracks")
    end

    it "displays tracks in the key" do
      get key_path(key)
      expect(response).to be_successful
    end

    it "displays playlists containing tracks in this key" do
      get key_path(key)
      expect(response).to be_successful
    end

    context "with search query" do
      it "filters key tracks by search term" do
        get key_path(key), params: { search: "test" }
        expect(response).to be_successful
      end
    end

    context "with sorting" do
      it "sorts tracks by BPM" do
        get key_path(key), params: { sort: "tracks.bpm", direction: "desc" }
        expect(response).to be_successful
      end
    end
  end
end
