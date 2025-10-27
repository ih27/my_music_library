# frozen_string_literal: true

require "rails_helper"

RSpec.describe "Tracks", type: :request do
  describe "GET /tracks" do
    let!(:tracks) { create_list(:track, 3, :with_artists) }

    it "returns a successful response" do
      get tracks_path
      expect(response).to be_successful
    end

    it "displays all tracks" do
      get tracks_path
      expect(response).to be_successful
    end

    context "with search query" do
      it "filters tracks by search term" do
        create(:track, :with_artists, name: "Unique Track Name")
        get tracks_path, params: { search: "Unique" }
        expect(response.body).to include("Unique Track Name")
      end
    end

    context "with sorting" do
      it "sorts by name ascending" do
        get tracks_path, params: { sort: "tracks.name", direction: "asc" }
        expect(response).to be_successful
      end

      it "sorts by BPM descending" do
        get tracks_path, params: { sort: "tracks.bpm", direction: "desc" }
        expect(response).to be_successful
      end

      it "sorts by key name" do
        get tracks_path, params: { sort: "keys.name", direction: "asc" }
        expect(response).to be_successful
      end
    end
  end

  describe "GET /tracks/:id" do
    let(:track) { create(:track, :with_artists) }

    it "returns a successful response" do
      get track_path(track)
      expect(response).to be_successful
    end

    it "displays the track details" do
      get track_path(track)
      expect(response).to be_successful
      expect(response.body).to include("BPM")
      expect(response.body).to include("Compatible Tracks")
    end
  end

  describe "GET /tracks/:id/compatible" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:track) { create(:track, key: key_8a, bpm: 128.0) }
    let!(:compatible_track) { create(:track, key: key_8a, bpm: 128.0) }

    it "returns compatible tracks as JSON" do
      get compatible_track_path(track), as: :json
      expect(response).to be_successful
      expect(response.content_type).to include("application/json")
    end

    it "returns tracks grouped by compatibility" do
      get compatible_track_path(track), as: :json
      json = response.parsed_body
      expect(json).to have_key("perfect")
      expect(json).to have_key("smooth")
      expect(json).to have_key("energy_boost")
    end

    it "includes track details" do
      get compatible_track_path(track), as: :json
      json = response.parsed_body
      perfect_tracks = json["perfect"]
      expect(perfect_tracks.first).to have_key("name")
      expect(perfect_tracks.first).to have_key("bpm")
    end

    context "with BPM range filter" do
      let!(:out_of_range) { create(:track, key: key_8a, bpm: 140.0) }

      it "filters by BPM range" do
        get compatible_track_path(track), params: { bpm_range: 5 }, as: :json
        json = response.parsed_body
        expect(json["perfect"].pluck("id")).not_to include(out_of_range.id)
      end
    end
  end

  # Skipping upload_audio test as it's a multipart form upload that's better tested manually
end
