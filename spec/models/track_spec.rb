# frozen_string_literal: true

require "rails_helper"

RSpec.describe Track, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:key).optional }
    it { is_expected.to have_many(:playlists_tracks).dependent(:destroy) }
    it { is_expected.to have_many(:playlists).through(:playlists_tracks) }
    it { is_expected.to have_and_belong_to_many(:artists) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_presence_of(:bpm) }
    it { is_expected.to validate_presence_of(:date_added) }
  end

  describe ".search" do
    let!(:key) { create(:key, name: "8A") }
    let!(:artist) { create(:artist, name: "Daft Punk") }
    let!(:playlist) { create(:playlist, name: "House Mix") }
    let!(:track) do
      create(:track, name: "Around the World", bpm: 121.0, key: key, artists: [artist])
    end

    before do
      PlaylistsTrack.create!(playlist: playlist, track: track, order: 1)
    end

    it "finds tracks by name" do
      expect(described_class.search("around")).to include(track)
    end

    it "finds tracks by artist name" do
      expect(described_class.search("daft")).to include(track)
    end

    it "finds tracks by BPM" do
      expect(described_class.search("121")).to include(track)
    end

    it "finds tracks by key" do
      expect(described_class.search("8A")).to include(track)
    end

    it "finds tracks by playlist name" do
      expect(described_class.search("house")).to include(track)
    end

    it "returns empty for non-matching query" do
      expect(described_class.search("nonexistent")).to be_empty
    end

    it "is case insensitive" do
      expect(described_class.search("AROUND")).to include(track)
    end
  end

  describe "#find_compatible" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:track1) { create(:track, key: key_8a, bpm: 128.0) }
    let!(:track2) { create(:track, key: key_8a, bpm: 128.0) }
    let!(:track3) { create(:track, key: key_8b, bpm: 130.0) }

    it "returns compatible tracks grouped by type" do
      result = track1.find_compatible
      expect(result).to have_key(:perfect)
      expect(result).to have_key(:smooth)
      expect(result).to have_key(:energy_boost)
    end

    it "finds perfect matches" do
      result = track1.find_compatible
      expect(result[:perfect]).to include(track2)
    end

    it "finds smooth matches" do
      result = track1.find_compatible
      expect(result[:smooth]).to include(track3)
    end

    context "with BPM range" do
      it "filters by BPM range" do
        result = track1.find_compatible(bpm_range: 1)
        expect(result[:smooth]).not_to include(track3)
      end
    end
  end

  describe "#compatible_with?" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:track1) { create(:track, key: key_8a, bpm: 128.0) }
    let(:track2) { create(:track, key: key_8a, bpm: 128.0) }
    let(:track3) { create(:track, key: key_8b, bpm: 130.0) }

    it "returns true for compatible keys" do
      expect(track1.compatible_with?(track2)).to be true
    end

    it "returns true for smooth transitions" do
      expect(track1.compatible_with?(track3)).to be true
    end

    it "returns false when track has no key" do
      track_without_key = create(:track, :without_key)
      expect(track1.compatible_with?(track_without_key)).to be false
    end

    it "returns false when other track is nil" do
      expect(track1.compatible_with?(nil)).to be false
    end

    context "with BPM range" do
      it "returns true when within BPM range" do
        expect(track1.compatible_with?(track3, bpm_range: 5)).to be true
      end

      it "returns false when outside BPM range" do
        expect(track1.compatible_with?(track3, bpm_range: 1)).to be false
      end
    end
  end
end
