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

  describe "#convert_to_dj_set" do
    let(:playlist) { create(:playlist, :with_tracks, name: "Summer Vibes 2024", tracks_count: 5) }

    it "creates a new DJ Set" do
      expect { playlist.convert_to_dj_set }.to change(DjSet, :count).by(1)
    end

    it "uses default name with (DJ Set) suffix" do
      dj_set = playlist.convert_to_dj_set
      expect(dj_set.name).to eq("Summer Vibes 2024 (DJ Set)")
    end

    it "accepts custom name" do
      dj_set = playlist.convert_to_dj_set(name: "Custom Set Name")
      expect(dj_set.name).to eq("Custom Set Name")
    end

    it "sets description noting the source playlist" do
      dj_set = playlist.convert_to_dj_set
      expect(dj_set.description).to include("Converted from playlist: Summer Vibes 2024")
    end

    it "copies all tracks in exact order" do
      dj_set = playlist.convert_to_dj_set
      expect(dj_set.tracks.count).to eq(playlist.tracks.count)

      playlist.playlists_tracks.order(:order).each_with_index do |pt, index|
        dj_set_track = dj_set.dj_sets_tracks.order(:order)[index]
        expect(dj_set_track.track).to eq(pt.track)
        expect(dj_set_track.order).to eq(pt.order)
      end
    end

    it "does not delete the original playlist" do
      playlist # Force creation
      expect { playlist.convert_to_dj_set }.not_to change(described_class, :count)
      expect(described_class.exists?(playlist.id)).to be true
    end

    it "does not modify the original playlist tracks" do
      original_track_count = playlist.tracks.count
      original_track_ids = playlist.tracks.order(:id).pluck(:id)

      playlist.convert_to_dj_set

      expect(playlist.reload.tracks.count).to eq(original_track_count)
      expect(playlist.tracks.order(:id).pluck(:id)).to eq(original_track_ids)
    end

    it "returns the created DJ Set" do
      dj_set = playlist.convert_to_dj_set
      expect(dj_set).to be_a(DjSet)
      expect(dj_set).to be_persisted
    end

    context "with empty playlist" do
      let(:empty_playlist) { create(:playlist, name: "Empty Playlist") }

      it "creates DJ Set with no tracks" do
        dj_set = empty_playlist.convert_to_dj_set
        expect(dj_set.tracks.count).to eq(0)
      end
    end

    context "with duplicate name" do
      before do
        create(:dj_set, name: "Summer Vibes 2024 (DJ Set)")
      end

      it "raises validation error" do
        expect { playlist.convert_to_dj_set }.to raise_error(ActiveRecord::RecordInvalid, /Name has already been taken/)
      end

      it "allows conversion with custom name" do
        expect { playlist.convert_to_dj_set(name: "Summer Vibes 2024 v2") }.not_to raise_error
      end
    end
  end
end
