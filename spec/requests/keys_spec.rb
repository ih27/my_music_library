# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Keys", type: :request do
  describe "GET /keys" do
    let!(:keys) { create_list(:key, 5) }

    it "displays all keys" do
      get keys_path
      expect(response).to be_successful
      expect(response.body).to include("Keys")
    end
  end

  describe "GET /keys/:id" do
    let(:key) { create(:key, :camelot_8a) }
    let!(:track_slow) { create(:track, name: "Slow Track", key: key, bpm: 100) }
    let!(:track_fast) { create(:track, name: "Fast Track", key: key, bpm: 140) }
    let!(:playlist) { create(:playlist) }

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track_slow, order: 1)
    end

    it "displays the key details and tracks" do
      get key_path(key)
      expect(response).to be_successful
      expect(response.body).to include("Total Tracks")
      expect(response.body).to include("Slow Track")
      expect(response.body).to include("Fast Track")
    end

    context "with search query" do
      it "accepts search parameters" do
        get key_path(key), params: { search: "Track" }
        expect(response).to be_successful
      end
    end

    context "with sorting" do
      it "accepts sorting parameters" do
        get key_path(key), params: { sort: "tracks.bpm", direction: "desc" }
        expect(response).to be_successful
      end
    end
  end
end
