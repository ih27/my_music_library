# frozen_string_literal: true

require "rails_helper"

RSpec.describe Playlist, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:playlists_tracks).dependent(:destroy) }
    it { is_expected.to have_many(:tracks).through(:playlists_tracks) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "callbacks" do
    describe "after_create" do
      it "attaches default cover art" do
        playlist = create(:playlist)
        expect(playlist.cover_art).to be_attached
      end

      it "uses default_cover_art.jpg" do
        playlist = create(:playlist)
        expect(playlist.cover_art.filename.to_s).to eq("default_cover_art.jpg")
      end
    end
  end

  describe "#unique_identifier" do
    let(:playlist) { create(:playlist, :with_tracks, tracks_count: 3) }

    it "returns a string of track IDs joined by dashes" do
      track_ids = playlist.tracks.order(:id).pluck(:id).join("-")
      expect(playlist.unique_identifier).to eq(track_ids)
    end

    it "returns empty string for playlist without tracks" do
      empty_playlist = create(:playlist)
      expect(empty_playlist.unique_identifier).to eq("")
    end

    it "returns same identifier for same tracks in same order" do
      tracks = playlist.tracks
      playlist2 = create(:playlist)
      tracks.each_with_index do |track, index|
        PlaylistsTrack.create!(playlist: playlist2, track: track, order: index + 1)
      end
      expect(playlist.unique_identifier).to eq(playlist2.unique_identifier)
    end
  end

  describe "#analyze_transitions" do
    let(:playlist) { create(:playlist, :with_harmonic_flow) }

    it "returns an array of transitions" do
      transitions = playlist.analyze_transitions
      expect(transitions).to be_an(Array)
      expect(transitions.length).to be > 0
    end

    it "includes transition details" do
      transitions = playlist.analyze_transitions
      first_transition = transitions.first
      expect(first_transition).to have_key(:from)
      expect(first_transition).to have_key(:to)
      expect(first_transition).to have_key(:quality)
      expect(first_transition).to have_key(:indicator)
    end
  end

  describe "#harmonic_flow_score" do
    let(:playlist) { create(:playlist, :with_harmonic_flow) }

    it "returns a score between 0 and 100" do
      score = playlist.harmonic_flow_score
      expect(score).to be >= 0
      expect(score).to be <= 100
    end

    it "returns higher score for harmonically compatible tracks" do
      score = playlist.harmonic_flow_score
      expect(score).to be > 50
    end
  end

  describe "#harmonic_analysis" do
    let(:playlist) { create(:playlist, :with_harmonic_flow) }

    it "returns complete analysis hash" do
      analysis = playlist.harmonic_analysis
      expect(analysis).to have_key(:transitions)
      expect(analysis).to have_key(:score)
      expect(analysis).to have_key(:total_transitions)
      expect(analysis).to have_key(:quality_counts)
    end

    it "includes quality counts" do
      analysis = playlist.harmonic_analysis
      quality_counts = analysis[:quality_counts]
      # Quality counts only include types that actually occur
      expect(quality_counts).to be_a(Hash)
      expect(quality_counts.keys).to all(be_in(%i[perfect smooth energy_boost rough]))
    end
  end
end
