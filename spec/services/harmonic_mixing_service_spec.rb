# frozen_string_literal: true

require "rails_helper"

RSpec.describe HarmonicMixingService do
  describe "#find_compatible_tracks" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:key_7a) { create(:key, :camelot_7a) }
    let(:key_3a) { create(:key, :camelot_3a) }
    let(:track) { create(:track, key: key_8a, bpm: 128.0) }

    let!(:perfect_match) { create(:track, key: key_8a, bpm: 128.0) }
    let!(:smooth_match1) { create(:track, key: key_8b, bpm: 128.0) }
    let!(:smooth_match2) { create(:track, key: key_7a, bpm: 128.0) }
    let!(:energy_match) { create(:track, key: key_3a, bpm: 128.0) }

    context "without BPM range" do
      it "finds perfect matches" do
        service = described_class.new(track)
        result = service.find_compatible_tracks
        expect(result[:perfect]).to include(perfect_match)
      end

      it "finds smooth matches" do
        service = described_class.new(track)
        result = service.find_compatible_tracks
        expect(result[:smooth]).to include(smooth_match1, smooth_match2)
      end

      it "finds energy boost matches" do
        service = described_class.new(track)
        result = service.find_compatible_tracks
        expect(result[:energy_boost]).to include(energy_match)
      end

      it "excludes the track itself" do
        service = described_class.new(track)
        result = service.find_compatible_tracks
        expect(result[:perfect]).not_to include(track)
      end
    end

    context "with BPM range" do
      let!(:out_of_range_track) { create(:track, key: key_8a, bpm: 140.0) }

      it "filters tracks by BPM range" do
        service = described_class.new(track, bpm_range: 5)
        result = service.find_compatible_tracks
        expect(result[:perfect]).not_to include(out_of_range_track)
      end

      it "includes tracks within BPM range" do
        within_range = create(:track, key: key_8a, bpm: 130.0)
        service = described_class.new(track, bpm_range: 5)
        result = service.find_compatible_tracks
        expect(result[:perfect]).to include(within_range)
      end
    end

    context "when track has no key" do
      let(:keyless_track) { create(:track, :without_key) }

      it "returns empty arrays" do
        service = described_class.new(keyless_track)
        result = service.find_compatible_tracks
        expect(result[:perfect]).to be_empty
        expect(result[:smooth]).to be_empty
        expect(result[:energy_boost]).to be_empty
      end
    end
  end

  describe ".analyze_playlist_transitions" do
    let(:playlist) { create(:playlist, :with_harmonic_flow) }

    it "returns hash with required keys" do
      result = described_class.analyze_playlist_transitions(playlist)
      expect(result).to have_key(:transitions)
      expect(result).to have_key(:score)
      expect(result).to have_key(:total_transitions)
      expect(result).to have_key(:quality_counts)
    end

    it "analyzes transitions correctly" do
      result = described_class.analyze_playlist_transitions(playlist)
      expect(result[:transitions].size).to be > 0
    end

    it "includes transition details" do
      result = described_class.analyze_playlist_transitions(playlist)
      first_transition = result[:transitions].first
      expect(first_transition).to have_key(:from)
      expect(first_transition).to have_key(:to)
      expect(first_transition).to have_key(:quality)
      expect(first_transition).to have_key(:indicator)
    end

    it "calculates score" do
      result = described_class.analyze_playlist_transitions(playlist)
      expect(result[:score]).to be >= 0
      expect(result[:score]).to be <= 100
    end

    it "counts transitions by quality" do
      result = described_class.analyze_playlist_transitions(playlist)
      quality_counts = result[:quality_counts]
      expect(quality_counts).to be_a(Hash)
    end

    context "with empty playlist" do
      let(:empty_playlist) { create(:playlist) }

      it "returns empty transitions" do
        result = described_class.analyze_playlist_transitions(empty_playlist)
        expect(result[:transitions]).to be_empty
      end

      it "returns perfect score for empty playlist" do
        result = described_class.analyze_playlist_transitions(empty_playlist)
        expect(result[:score]).to eq(100.0)
      end
    end

    context "with tracks missing keys" do
      let(:playlist) { create(:playlist) }
      let!(:track1) { create(:track, :without_key) }
      let!(:track2) { create(:track, :without_key) }

      before do
        PlaylistsTrack.create!(playlist: playlist, track: track1, order: 1)
        PlaylistsTrack.create!(playlist: playlist, track: track2, order: 2)
      end

      it "skips transitions with missing keys" do
        result = described_class.analyze_playlist_transitions(playlist)
        expect(result[:transitions]).to be_empty
      end
    end
  end
end
