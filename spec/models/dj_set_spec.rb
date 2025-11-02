# frozen_string_literal: true

require "rails_helper"

RSpec.describe DjSet, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:dj_sets_tracks).dependent(:destroy) }
    it { is_expected.to have_many(:tracks).through(:dj_sets_tracks) }
  end

  describe "validations" do
    subject { create(:dj_set) }

    it { is_expected.to validate_presence_of(:name) }
    it { is_expected.to validate_uniqueness_of(:name).case_insensitive }
    it { is_expected.to validate_length_of(:name).is_at_most(100) }
    it { is_expected.to validate_length_of(:description).is_at_most(500) }
  end

  describe "#ordered_tracks" do
    let(:dj_set) { create(:dj_set) }
    let!(:track1) { create(:track) }
    let!(:track2) { create(:track) }
    let!(:track3) { create(:track) }

    before do
      DjSetsTrack.create!(dj_set: dj_set, track: track3, order: 3)
      DjSetsTrack.create!(dj_set: dj_set, track: track1, order: 1)
      DjSetsTrack.create!(dj_set: dj_set, track: track2, order: 2)
    end

    it "returns tracks in order" do
      expect(dj_set.ordered_tracks).to eq([track1, track2, track3])
    end

    it "maintains order after reload" do
      dj_set.reload
      expect(dj_set.ordered_tracks).to eq([track1, track2, track3])
    end
  end

  describe "#analyze_transitions" do
    let(:dj_set) { create(:dj_set, :with_harmonic_flow) }

    it "returns an array of transitions" do
      transitions = dj_set.analyze_transitions
      expect(transitions).to be_an(Array)
      expect(transitions.length).to be > 0
    end

    it "includes transition details" do
      transitions = dj_set.analyze_transitions
      first_transition = transitions.first
      expect(first_transition).to have_key(:from)
      expect(first_transition).to have_key(:to)
      expect(first_transition).to have_key(:quality)
      expect(first_transition).to have_key(:indicator)
    end

    it "returns empty array for set with less than 2 tracks" do
      empty_set = create(:dj_set)
      expect(empty_set.analyze_transitions).to eq([])
    end
  end

  describe "#harmonic_flow_score" do
    let(:dj_set) { create(:dj_set, :with_harmonic_flow) }

    it "returns a score between 0 and 100" do
      score = dj_set.harmonic_flow_score
      expect(score).to be >= 0
      expect(score).to be <= 100
    end

    it "returns higher score for harmonically compatible tracks" do
      score = dj_set.harmonic_flow_score
      expect(score).to be > 50
    end

    it "returns 100 for set with less than 2 tracks (no transitions = perfect score)" do
      empty_set = create(:dj_set)
      expect(empty_set.harmonic_flow_score).to eq(100.0)
    end
  end

  describe "#harmonic_analysis" do
    let(:dj_set) { create(:dj_set, :with_harmonic_flow) }

    it "returns complete analysis hash" do
      analysis = dj_set.harmonic_analysis
      expect(analysis).to have_key(:transitions)
      expect(analysis).to have_key(:score)
      expect(analysis).to have_key(:total_transitions)
      expect(analysis).to have_key(:quality_counts)
    end

    it "includes quality counts" do
      analysis = dj_set.harmonic_analysis
      quality_counts = analysis[:quality_counts]
      expect(quality_counts).to be_a(Hash)
      expect(quality_counts.keys).to all(be_in(%i[perfect smooth energy_boost rough]))
    end
  end

  describe "#duplicate" do
    let(:original_set) { create(:dj_set, :with_tracks, tracks_count: 3, name: "Original Set") }

    it "creates a new set with the given name" do
      duplicated = original_set.duplicate(new_name: "Duplicated Set")
      expect(duplicated.name).to eq("Duplicated Set")
      expect(duplicated.id).not_to eq(original_set.id)
    end

    it "copies all tracks in the same order" do
      duplicated = original_set.duplicate(new_name: "Duplicated Set")
      expect(duplicated.tracks.pluck(:id)).to eq(original_set.tracks.pluck(:id))
      expect(duplicated.dj_sets_tracks.order(:order).pluck(:order))
        .to eq(original_set.dj_sets_tracks.order(:order).pluck(:order))
    end

    it "copies description if present" do
      original_set.update(description: "Test description")
      duplicated = original_set.duplicate(new_name: "Duplicated Set")
      expect(duplicated.description).to eq("Test description")
    end

    it "uses default name if not provided" do
      duplicated = original_set.duplicate
      expect(duplicated.name).to eq("Original Set (Copy)")
    end
  end

  describe "#export_to_file" do
    let(:dj_set) { create(:dj_set, :with_tracks, tracks_count: 2) }

    it "returns a text file content" do
      content = dj_set.export_to_file
      expect(content).to be_a(String)
    end

    it "includes headers" do
      content = dj_set.export_to_file
      expect(content).to include("Track Title")
      expect(content).to include("Artist")
    end

    it "includes track information" do
      track = dj_set.tracks.first
      content = dj_set.export_to_file
      expect(content).to include(track.name)
    end

    it "includes track order numbers" do
      content = dj_set.export_to_file
      expect(content).to match(/^1\t/)
      expect(content).to match(/^2\t/)
    end
  end

  describe "#convert_to_playlist" do
    let(:dj_set) { create(:dj_set, :with_tracks, tracks_count: 3, name: "Test Set") }

    it "creates a new playlist" do
      expect do
        dj_set.convert_to_playlist(name: "Test Playlist")
      end.to change(Playlist, :count).by(1)
    end

    it "copies all tracks to the new playlist" do
      playlist = dj_set.convert_to_playlist(name: "Test Playlist")
      expect(playlist.tracks.pluck(:id)).to eq(dj_set.tracks.pluck(:id))
    end

    it "maintains track order" do
      playlist = dj_set.convert_to_playlist(name: "Test Playlist")
      expect(playlist.playlists_tracks.order(:order).pluck(:order))
        .to eq(dj_set.dj_sets_tracks.order(:order).pluck(:order))
    end

    it "uses set name as default playlist name" do
      playlist = dj_set.convert_to_playlist
      expect(playlist.name).to eq("Test Set")
    end

    it "accepts custom name" do
      playlist = dj_set.convert_to_playlist(name: "Custom Playlist Name")
      expect(playlist.name).to eq("Custom Playlist Name")
    end
  end
end
