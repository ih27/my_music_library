# frozen_string_literal: true

require "rails_helper"

RSpec.describe DjSetsTrack, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:dj_set) }
    it { is_expected.to belong_to(:track) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:order) }
    it { is_expected.to validate_numericality_of(:order).only_integer.is_greater_than(0) }
  end

  describe "uniqueness validation" do
    let(:dj_set) { create(:dj_set) }
    let(:track) { create(:track) }

    before do
      described_class.create!(dj_set: dj_set, track: track, order: 1)
    end

    it "prevents duplicate track in same set" do
      duplicate = described_class.new(dj_set: dj_set, track: track, order: 2)
      expect(duplicate).not_to be_valid
      expect(duplicate.errors[:track_id]).to include("already in set")
    end

    it "allows same track in different sets" do
      other_set = create(:dj_set, name: "Other Set")
      duplicate = described_class.new(dj_set: other_set, track: track, order: 1)
      expect(duplicate).to be_valid
    end
  end

  describe "ordering" do
    let(:dj_set) { create(:dj_set) }
    let!(:track1) { create(:track) }
    let!(:track2) { create(:track) }
    let!(:track3) { create(:track) }

    before do
      described_class.create!(dj_set: dj_set, track: track1, order: 1)
      described_class.create!(dj_set: dj_set, track: track2, order: 2)
      described_class.create!(dj_set: dj_set, track: track3, order: 3)
    end

    it "maintains order when queried" do
      ordered_tracks = dj_set.dj_sets_tracks.order(:order).map(&:track)
      expect(ordered_tracks).to eq([track1, track2, track3])
    end

    it "allows reordering" do
      dj_set.dj_sets_tracks.find_by(track: track1).update(order: 3)
      dj_set.dj_sets_tracks.find_by(track: track3).update(order: 1)
      ordered_tracks = dj_set.dj_sets_tracks.order(:order).map(&:track)
      expect(ordered_tracks).to eq([track3, track2, track1])
    end
  end
end
