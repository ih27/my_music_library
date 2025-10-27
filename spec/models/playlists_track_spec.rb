# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaylistsTrack, type: :model do
  describe "associations" do
    it { is_expected.to belong_to(:playlist) }
    it { is_expected.to belong_to(:track) }
  end

  describe "ordering" do
    let(:playlist) { create(:playlist) }
    let(:track1) { create(:track) }
    let(:track2) { create(:track) }
    let(:track3) { create(:track) }

    it "maintains track order" do
      pt1 = described_class.create!(playlist: playlist, track: track1, order: 1)
      pt2 = described_class.create!(playlist: playlist, track: track2, order: 2)
      pt3 = described_class.create!(playlist: playlist, track: track3, order: 3)

      ordered = playlist.playlists_tracks.order(:order)
      expect(ordered).to eq([pt1, pt2, pt3])
    end
  end
end
