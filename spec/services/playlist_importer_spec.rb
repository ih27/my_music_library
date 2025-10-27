# frozen_string_literal: true

require "rails_helper"

RSpec.describe PlaylistImporter do
  describe "#call" do
    let(:playlist) { build(:playlist, name: "Test Playlist") }

    context "with valid file" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:importer) { described_class.new(playlist, file) }

      it "creates the playlist" do
        expect { importer.call }.to change(Playlist, :count).by(1)
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

      it "creates playlist-track associations" do
        expect { importer.call }.to change(PlaylistsTrack, :count)
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
        playlist.reload
        track_names = playlist.tracks.order("playlists_tracks.\"order\"").pluck(:name)
        expect(track_names).to eq(["Test Song 1", "Test Song 2", "Test Song 3"])
      end

      it "creates all tracks on first import" do
        expect { importer.call }.to change(Track, :count).by(3)
      end
    end

    context "with minimal file (only required headers)" do
      let(:file) { Rails.root.join("spec/fixtures/files/minimal_playlist.txt").open }
      let(:importer) { described_class.new(playlist, file) }

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

    context "with duplicate playlist" do
      let(:file) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:importer1) { described_class.new(playlist, file) }
      let(:duplicate_playlist) { build(:playlist, name: "Duplicate") }
      let(:file2) { Rails.root.join("spec/fixtures/files/valid_playlist.txt").open }
      let(:importer2) { described_class.new(duplicate_playlist, file2) }

      it "prevents duplicate imports" do
        importer1.call
        expect(importer2.call).to be false
      end

      it "does not create duplicate playlist" do
        importer1.call
        expect { importer2.call }.not_to change(Playlist, :count)
      end
    end

    context "with no file" do
      let(:importer) { described_class.new(playlist, nil) }

      it "returns false" do
        expect(importer.call).to be false
      end

      it "does not create playlist" do
        expect { importer.call }.not_to change(Playlist, :count)
      end
    end

    context "with empty file" do
      let(:empty_file) { StringIO.new("#\tTrack Title\tArtist\tBPM\tDate Added\n") }
      let(:importer) { described_class.new(playlist, empty_file) }

      it "returns false" do
        expect(importer.call).to be false
      end

      it "does not create playlist" do
        expect { importer.call }.not_to change(Playlist, :count)
      end
    end
  end

  describe "encoding detection" do
    let(:playlist) { build(:playlist, name: "Test Playlist") }

    it "handles UTF-8 files" do
      content = "#\tTrack Title\tArtist\tBPM\tDate Added\n1\tTest\tArtist\t128.0\t2024-01-01\n"
      file = StringIO.new(content)
      importer = described_class.new(playlist, file)
      expect(importer.call).to be true
    end

    it "handles files with BOM" do
      content = "\xEF\xBB\xBF#\tTrack Title\tArtist\tBPM\tDate Added\n1\tTest\tArtist\t128.0\t2024-01-01\n"
      file = StringIO.new(content)
      importer = described_class.new(playlist, file)
      expect(importer.call).to be true
    end
  end

  describe "error handling" do
    let(:playlist) { build(:playlist, name: "Test Playlist") }

    it "handles missing required headers" do
      content = "Wrong\tHeaders\n1\tTest\n"
      file = StringIO.new(content)
      importer = described_class.new(playlist, file)
      expect { importer.call }.to raise_error(/Missing required header/)
    end

    it "handles malformed lines gracefully" do
      # Create file with a line that has missing columns
      content = "#\tTrack Title\tArtist\tBPM\tDate Added\n1\tTest Song\n"
      file = StringIO.new(content)
      importer = described_class.new(playlist, file)

      # The importer skips invalid lines
      expect(importer.call).to be false # Returns false because no valid tracks were parsed
    end
  end
end
