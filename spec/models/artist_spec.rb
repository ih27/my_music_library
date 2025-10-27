# frozen_string_literal: true

require "rails_helper"

RSpec.describe Artist, type: :model do
  describe "associations" do
    it { is_expected.to have_and_belong_to_many(:tracks) }
  end

  describe "validations" do
    it { is_expected.to validate_presence_of(:name) }
  end

  describe "callbacks" do
    describe "before_destroy" do
      context "when artist has tracks" do
        let(:artist) { create(:artist) }
        let(:track) { create(:track, artists: [artist]) }

        it "prevents deletion" do
          track # Create the track first
          expect { artist.destroy }.not_to change(described_class, :count)
        end

        it "returns false" do
          track # Create the track first
          expect(artist.destroy).to be false
        end
      end

      context "when artist has no tracks" do
        let(:artist) { create(:artist) }

        it "allows deletion" do
          artist # Create the artist first
          expect { artist.destroy }.to change(described_class, :count).by(-1)
        end
      end
    end
  end
end
