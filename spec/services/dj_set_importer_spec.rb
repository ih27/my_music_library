# frozen_string_literal: true

require "rails_helper"

RSpec.describe DjSetImporter do
  describe "#call" do
    let(:dj_set) { build(:dj_set, name: "Test Set") }

    context "with valid file" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:importer) { described_class.new(dj_set, file) }

      it "creates the DJ set" do
        expect { importer.call }.to change(DjSet, :count).by(1)
      end

      it "creates tracks" do
        expect { importer.call }.to change(Track, :count)
      end

      it "creates artists" do
        expect { importer.call }.to change(Artist, :count)
      end

      it "creates keys" do
        expect { importer.call }.to change(Key, :count)
      end

      it "creates DJ set-track associations" do
        expect { importer.call }.to change(DjSetsTrack, :count)
      end

      it "returns true on success" do
        expect(importer.call).to be true
      end

      it "parses track attributes correctly" do
        importer.call
        track = Track.find_by(name: "Test Song 1")
        expect(track).to be_present
        expect(track.bpm).to eq(128.0)
        expect(track.album).to eq("Test Album")
      end

      it "parses time correctly" do
        importer.call
        track = Track.find_by(name: "Test Song 1")
        expect(track.time).to eq(270) # 4:30 = 270 seconds
      end

      it "associates artists with tracks" do
        importer.call
        track = Track.find_by(name: "Test Song 3")
        expect(track.artists.count).to eq(2)
        expect(track.artists.pluck(:name)).to include("Artist One", "Artist Two")
      end

      it "maintains track order" do
        importer.call
        dj_set.reload
        track_names = dj_set.ordered_tracks.pluck(:name)
        expect(track_names).to eq(["Test Song 1", "Test Song 2", "Test Song 3"])
      end

      it "creates all tracks on first import" do
        expect { importer.call }.to change(Track, :count).by(3)
      end
    end

    context "with minimal file (only required headers)" do
      let(:file) { Rails.root.join("spec/fixtures/files/minimal_playlist.txt").open }
      let(:importer) { described_class.new(dj_set, file) }

      it "successfully imports" do
        expect(importer.call).to be true
      end

      it "creates track without optional fields" do
        importer.call
        track = Track.find_by(name: "Minimal Song")
        expect(track).to be_present
        expect(track.key).to be_nil
        expect(track.time).to be_nil
        expect(track.album).to be_nil
      end
    end

    context "with existing DJ set (appending tracks)" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:existing_set) { create(:dj_set, name: "Existing Set") }
      let(:existing_track) { create(:track, name: "Existing Track") }

      before do
        existing_set.dj_sets_tracks.create!(track: existing_track, order: 1)
      end

      it "appends new tracks to existing set" do
        importer = described_class.new(existing_set, file)
        expect { importer.call }.to change { existing_set.tracks.count }.from(1).to(4)
      end

      it "maintains sequential order after appending" do
        importer = described_class.new(existing_set, file)
        importer.call
        existing_set.reload

        orders = existing_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq([1, 2, 3, 4])
      end

      it "preserves existing tracks" do
        importer = described_class.new(existing_set, file)
        importer.call
        existing_set.reload

        expect(existing_set.ordered_tracks.first).to eq(existing_track)
      end
    end

    context "with duplicate tracks in same set" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:importer) { described_class.new(dj_set, file) }

      before do
        # First import
        importer.call
        dj_set.reload
      end

      it "skips duplicate tracks when importing again" do
        file2 = Rails.root.join("spec/fixtures/files/valid_playlist.txt").open
        importer2 = described_class.new(dj_set, file2)

        expect { importer2.call }.not_to(change { dj_set.tracks.count })
      end

      it "logs warning for duplicate tracks" do
        file2 = Rails.root.join("spec/fixtures/files/valid_playlist.txt").open
        importer2 = described_class.new(dj_set, file2)

        allow(Rails.logger).to receive(:warn)
        importer2.call
        expect(Rails.logger).to have_received(:warn).at_least(:once)
      end
    end

    context "with no file" do
      let(:importer) { described_class.new(dj_set, nil) }

      it "returns false" do
        expect(importer.call).to be false
      end

      it "does not create DJ set" do
        expect { importer.call }.not_to change(DjSet, :count)
      end
    end

    context "with invalid file format" do
      let(:file) { Tempfile.new(["invalid", ".txt"]) }
      let(:importer) { described_class.new(dj_set, file) }

      before do
        file.write("Invalid content without proper headers\n")
        file.rewind
      end

      after do
        file.close
        file.unlink
      end

      it "returns false for missing required headers" do
        expect(importer.call).to be false
      end

      it "does not create DJ set" do
        expect { importer.call }.not_to change(DjSet, :count)
      end
    end

    context "with encoding issues" do
      it "handles non-UTF-8 files" do
        file_path = Rails.root.join("spec/fixtures/files/utf16_playlist.txt")
        skip "UTF-16 test file not available" unless File.exist?(file_path)

        file = file_path.open
        importer = described_class.new(dj_set, file)
        expect(importer.call).to be true
      end
    end

    context "with gaps in track order" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:existing_set) { create(:dj_set, name: "Set with gaps") }
      let(:track1) { create(:track) }
      let(:track2) { create(:track) }

      before do
        # Create tracks with gaps in order (e.g., 1, 5, 10)
        existing_set.dj_sets_tracks.create!(track: track1, order: 1)
        existing_set.dj_sets_tracks.create!(track: track2, order: 5)
      end

      it "resequences all tracks to remove gaps" do
        importer = described_class.new(existing_set, file)
        importer.call
        existing_set.reload

        orders = existing_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq((1..orders.length).to_a)
      end
    end
  end
end
