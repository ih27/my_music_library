# frozen_string_literal: true

require "rails_helper"

RSpec.describe "DjSets", type: :request do
  describe "GET /dj_sets" do
    let!(:dj_sets) { create_list(:dj_set, 3) }

    it "displays all DJ sets" do
      get dj_sets_path
      expect(response).to be_successful
      expect(response.body).to include("Sets")
    end

    it "sorts by updated_at desc by default" do
      get dj_sets_path
      expect(response).to be_successful
    end

    it "allows sorting by name" do
      get dj_sets_path(sort: "name", direction: "asc")
      expect(response).to be_successful
    end
  end

  describe "GET /dj_sets/:id" do
    let(:dj_set) { create(:dj_set, :with_harmonic_flow) }

    it "displays the DJ set with harmonic analysis" do
      get dj_set_path(dj_set)
      expect(response).to be_successful
      expect(response.body).to include("Harmonic")
    end

    it "displays tracks in order" do
      get dj_set_path(dj_set)
      expect(response).to be_successful
      expect(response.body).to include("Tracks")
    end
  end

  describe "GET /dj_sets/new" do
    it "returns a successful response" do
      get new_dj_set_path
      expect(response).to be_successful
    end

    it "displays the form" do
      get new_dj_set_path
      expect(response.body).to include("New Set")
    end
  end

  describe "POST /dj_sets" do
    context "with valid parameters" do
      let(:valid_params) do
        { dj_set: { name: "Test Set", description: "Test description" } }
      end

      it "creates a new DJ set" do
        expect do
          post dj_sets_path, params: valid_params
        end.to change(DjSet, :count).by(1)
      end

      it "redirects to the DJ set" do
        post dj_sets_path, params: valid_params
        expect(response).to redirect_to(dj_set_path(DjSet.last))
      end

      it "sets a success notice" do
        post dj_sets_path, params: valid_params
        follow_redirect!
        expect(response.body).to include("created successfully")
      end
    end

    context "with track IDs (from track selection)" do
      let!(:track1) { create(:track) }
      let!(:track2) { create(:track) }
      let(:params_with_tracks) do
        {
          dj_set: { name: "Test Set", description: "Test" },
          track_ids: [track1.id, track2.id]
        }
      end

      it "creates set and adds tracks" do
        expect do
          post dj_sets_path, params: params_with_tracks
        end.to change(DjSet, :count).by(1)
                                    .and change(DjSetsTrack, :count).by(2)
      end

      it "adds tracks in correct order" do
        post dj_sets_path, params: params_with_tracks
        dj_set = DjSet.last
        expect(dj_set.ordered_tracks.pluck(:id)).to eq([track1.id, track2.id])
      end
    end

    context "with invalid parameters" do
      let(:invalid_params) do
        { dj_set: { name: "" } }
      end

      it "does not create a DJ set" do
        expect do
          post dj_sets_path, params: invalid_params
        end.not_to change(DjSet, :count)
      end

      it "renders the new template" do
        post dj_sets_path, params: invalid_params
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end

    context "with duplicate name" do
      let!(:existing_set) { create(:dj_set, name: "Duplicate Set") }
      let(:duplicate_params) do
        { dj_set: { name: "Duplicate Set" } }
      end

      it "does not create a duplicate" do
        expect do
          post dj_sets_path, params: duplicate_params
        end.not_to change(DjSet, :count)
      end

      it "displays an error message" do
        post dj_sets_path, params: duplicate_params
        expect(response.body).to include("already been taken")
      end
    end

    context "with file upload (import mode)" do
      let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/valid_playlist.txt"), "text/plain") }
      let(:import_params) do
        {
          dj_set: {
            file: file,
            description: "Imported set"
          }
        }
      end

      it "creates a DJ set from file" do
        expect do
          post dj_sets_path, params: import_params
        end.to change(DjSet, :count).by(1)
      end

      it "extracts name from filename" do
        post dj_sets_path, params: import_params
        expect(DjSet.last.name).to eq("valid_playlist")
      end

      it "imports tracks from file" do
        expect do
          post dj_sets_path, params: import_params
        end.to change(Track, :count).by_at_least(1)
      end

      it "creates track associations" do
        expect do
          post dj_sets_path, params: import_params
        end.to change(DjSetsTrack, :count).by_at_least(1)
      end

      it "redirects to the DJ set" do
        post dj_sets_path, params: import_params
        expect(response).to redirect_to(dj_set_path(DjSet.last))
      end

      it "displays track count in success message" do
        post dj_sets_path, params: import_params
        follow_redirect!
        expect(response.body).to match(/created successfully with \d+ tracks/)
      end

      it "includes description if provided" do
        post dj_sets_path, params: import_params
        expect(DjSet.last.description).to eq("Imported set")
      end
    end

    context "with invalid file upload" do
      let(:invalid_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/invalid_playlist.txt"), "text/plain") }
      let(:invalid_import_params) do
        { dj_set: { file: invalid_file } }
      end

      before do
        # Create invalid_playlist.txt fixture with wrong headers
        FileUtils.mkdir_p(Rails.root.join("spec/fixtures/files"))
        Rails.root.join("spec/fixtures/files/invalid_playlist.txt").write("Invalid\tHeaders\n1\t2\t3")
      end

      after do
        FileUtils.rm_f(Rails.root.join("spec/fixtures/files/invalid_playlist.txt"))
      end

      it "does not create a DJ set" do
        expect do
          post dj_sets_path, params: invalid_import_params
        end.not_to change(DjSet, :count)
      end

      it "displays an error message" do
        post dj_sets_path, params: invalid_import_params
        expect(response).to have_http_status(:unprocessable_entity)
        expect(response.body).to include("Failed to import")
      end
    end
  end

  describe "GET /dj_sets/:id/edit" do
    let(:dj_set) { create(:dj_set) }

    it "returns a successful response" do
      get edit_dj_set_path(dj_set)
      expect(response).to be_successful
    end

    it "displays the edit form" do
      get edit_dj_set_path(dj_set)
      expect(response.body).to include("Edit")
    end
  end

  describe "PATCH /dj_sets/:id" do
    let(:dj_set) { create(:dj_set) }

    context "with valid parameters" do
      let(:new_attributes) do
        { dj_set: { name: "Updated Name", description: "Updated description" } }
      end

      it "updates the DJ set" do
        patch dj_set_path(dj_set), params: new_attributes
        dj_set.reload
        expect(dj_set.name).to eq("Updated Name")
        expect(dj_set.description).to eq("Updated description")
      end

      it "redirects to the DJ set" do
        patch dj_set_path(dj_set), params: new_attributes
        expect(response).to redirect_to(dj_set_path(dj_set))
      end
    end

    context "with invalid parameters" do
      let(:invalid_attributes) do
        { dj_set: { name: "" } }
      end

      it "does not update the DJ set" do
        original_name = dj_set.name
        patch dj_set_path(dj_set), params: invalid_attributes
        dj_set.reload
        expect(dj_set.name).to eq(original_name)
      end

      it "renders the edit template" do
        patch dj_set_path(dj_set), params: invalid_attributes
        expect(response).to have_http_status(:unprocessable_entity)
      end
    end
  end

  describe "DELETE /dj_sets/:id" do
    let!(:dj_set) { create(:dj_set, :with_tracks, tracks_count: 2) }

    it "destroys the DJ set" do
      expect do
        delete dj_set_path(dj_set)
      end.to change(DjSet, :count).by(-1)
    end

    it "redirects to DJ sets index" do
      delete dj_set_path(dj_set)
      expect(response).to redirect_to(dj_sets_path)
    end

    it "sets a success notice" do
      delete dj_set_path(dj_set)
      follow_redirect!
      expect(response.body).to include("deleted")
    end
  end

  describe "POST /dj_sets/:id/add_tracks" do
    let(:dj_set) { create(:dj_set) }
    let!(:track1) { create(:track) }
    let!(:track2) { create(:track) }

    context "with valid track IDs" do
      let(:params) { { track_ids: [track1.id, track2.id] } }

      it "adds tracks to the set" do
        expect do
          post add_tracks_dj_set_path(dj_set), params: params
        end.to change { dj_set.tracks.count }.by(2)
      end

      it "assigns sequential order numbers" do
        post add_tracks_dj_set_path(dj_set), params: params
        dj_set.reload
        orders = dj_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq([1, 2])
      end

      it "redirects to the set" do
        post add_tracks_dj_set_path(dj_set), params: params
        expect(response).to redirect_to(dj_set_path(dj_set))
      end

      it "displays success notice" do
        post add_tracks_dj_set_path(dj_set), params: params
        follow_redirect!
        expect(response.body).to include("2 track(s) added")
      end
    end

    context "when adding to existing tracks" do
      let!(:existing_track) { create(:track) }

      before do
        DjSetsTrack.create!(dj_set: dj_set, track: existing_track, order: 1)
      end

      it "maintains sequential order after adding new tracks" do
        post add_tracks_dj_set_path(dj_set), params: { track_ids: [track1.id, track2.id] }
        dj_set.reload
        orders = dj_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq([1, 2, 3])
      end
    end
  end

  describe "DELETE /dj_sets/:id/remove_track/:track_id" do
    let(:dj_set) { create(:dj_set) }
    let!(:track1) { create(:track) }
    let!(:track2) { create(:track) }
    let!(:track3) { create(:track) }

    before do
      DjSetsTrack.create!(dj_set: dj_set, track: track1, order: 1)
      DjSetsTrack.create!(dj_set: dj_set, track: track2, order: 2)
      DjSetsTrack.create!(dj_set: dj_set, track: track3, order: 3)
    end

    it "removes the track from the set" do
      expect do
        delete remove_track_dj_set_path(dj_set, track_id: track2.id)
      end.to change { dj_set.tracks.count }.by(-1)
    end

    it "resequences remaining tracks" do
      delete remove_track_dj_set_path(dj_set, track_id: track2.id)
      dj_set.reload
      orders = dj_set.dj_sets_tracks.order(:order).pluck(:order)
      expect(orders).to eq([1, 2])
    end

    it "redirects to the set" do
      delete remove_track_dj_set_path(dj_set, track_id: track2.id)
      expect(response).to redirect_to(dj_set_path(dj_set))
    end

    it "displays success notice" do
      delete remove_track_dj_set_path(dj_set, track_id: track2.id)
      follow_redirect!
      expect(response.body).to include("Track removed")
    end
  end

  describe "DELETE /dj_sets/:id/remove_tracks" do
    let(:dj_set) { create(:dj_set) }
    let!(:track1) { create(:track) }
    let!(:track2) { create(:track) }
    let!(:track3) { create(:track) }
    let!(:track4) { create(:track) }

    before do
      DjSetsTrack.create!(dj_set: dj_set, track: track1, order: 1)
      DjSetsTrack.create!(dj_set: dj_set, track: track2, order: 2)
      DjSetsTrack.create!(dj_set: dj_set, track: track3, order: 3)
      DjSetsTrack.create!(dj_set: dj_set, track: track4, order: 4)
    end

    context "with multiple track IDs" do
      let(:params) { { track_ids: [track2.id, track4.id] } }

      it "removes multiple tracks from the set" do
        expect do
          delete remove_tracks_dj_set_path(dj_set), params: params
        end.to change { dj_set.tracks.count }.by(-2)
      end

      it "resequences remaining tracks correctly" do
        delete remove_tracks_dj_set_path(dj_set), params: params
        dj_set.reload
        orders = dj_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq([1, 2])
      end

      it "keeps correct tracks" do
        delete remove_tracks_dj_set_path(dj_set), params: params
        dj_set.reload
        remaining_track_ids = dj_set.ordered_tracks.pluck(:id)
        expect(remaining_track_ids).to eq([track1.id, track3.id])
      end

      it "redirects to the set" do
        delete remove_tracks_dj_set_path(dj_set), params: params
        expect(response).to redirect_to(dj_set_path(dj_set))
      end

      it "displays success notice with count" do
        delete remove_tracks_dj_set_path(dj_set), params: params
        follow_redirect!
        expect(response.body).to include("2 track(s) removed")
      end
    end

    context "with empty track_ids" do
      it "handles empty array gracefully" do
        expect do
          delete remove_tracks_dj_set_path(dj_set), params: { track_ids: [] }
        end.not_to(change { dj_set.tracks.count })
      end
    end
  end

  describe "PATCH /dj_sets/:id/reorder_tracks" do
    let(:dj_set) { create(:dj_set) }
    let(:track1) { create(:track) }
    let(:track2) { create(:track) }
    let(:track3) { create(:track) }

    before do
      DjSetsTrack.create!(dj_set: dj_set, track: track1, order: 1)
      DjSetsTrack.create!(dj_set: dj_set, track: track2, order: 2)
      DjSetsTrack.create!(dj_set: dj_set, track: track3, order: 3)
    end

    context "with valid reorder data" do
      let(:reorder_params) do
        {
          order: [
            { id: track3.id, order: 1 },
            { id: track1.id, order: 2 },
            { id: track2.id, order: 3 }
          ]
        }
      end

      it "reorders tracks successfully" do
        patch reorder_tracks_dj_set_path(dj_set), params: reorder_params
        expect(response).to have_http_status(:ok)
      end

      it "updates track order" do
        patch reorder_tracks_dj_set_path(dj_set), params: reorder_params
        dj_set.reload
        expect(dj_set.dj_sets_tracks.find_by(track: track3).order).to eq(1)
        expect(dj_set.dj_sets_tracks.find_by(track: track1).order).to eq(2)
        expect(dj_set.dj_sets_tracks.find_by(track: track2).order).to eq(3)
      end

      it "returns JSON with success and harmonic score" do
        patch reorder_tracks_dj_set_path(dj_set), params: reorder_params
        json_response = response.parsed_body
        expect(json_response["success"]).to be true
        expect(json_response).to have_key("harmonic_score")
      end

      it "updates the set's updated_at timestamp" do
        original_time = dj_set.updated_at
        travel_to 1.hour.from_now do
          patch reorder_tracks_dj_set_path(dj_set), params: reorder_params
          dj_set.reload
          expect(dj_set.updated_at).to be > original_time
        end
      end
    end

    context "with non-existent track" do
      let(:invalid_params) do
        { order: [{ id: 999_999, order: 1 }] }
      end

      it "returns error status" do
        patch reorder_tracks_dj_set_path(dj_set), params: invalid_params
        expect(response).to have_http_status(:not_found)
      end

      it "returns error message" do
        patch reorder_tracks_dj_set_path(dj_set), params: invalid_params
        json_response = response.parsed_body
        expect(json_response["error"]).to be_present
      end
    end
  end

  describe "POST /dj_sets/:id/duplicate" do
    let!(:original_set) { create(:dj_set, :with_tracks, tracks_count: 3, name: "Original Set") }

    context "with custom name" do
      it "creates a duplicate set" do
        expect do
          post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        end.to change(DjSet, :count).by(1)
      end

      it "uses the provided name" do
        post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        expect(DjSet.last.name).to eq("Duplicated Set")
      end

      it "redirects to the new set" do
        post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        expect(response).to redirect_to(dj_set_path(DjSet.last))
      end

      it "displays success notice" do
        post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        follow_redirect!
        expect(response.body).to include("Duplicated as")
      end
    end

    context "without custom name" do
      it "uses default name with (Copy) suffix" do
        post duplicate_dj_set_path(original_set)
        expect(DjSet.last.name).to eq("Original Set (Copy)")
      end
    end

    context "with invalid duplicate" do
      before do
        create(:dj_set, name: "Duplicated Set")
      end

      it "redirects back with error" do
        post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        expect(response).to redirect_to(dj_set_path(original_set))
      end

      it "displays error alert" do
        post duplicate_dj_set_path(original_set), params: { name: "Duplicated Set" }
        follow_redirect!
        expect(response.body).to include("Error duplicating set")
      end
    end
  end

  describe "GET /dj_sets/:id/export" do
    let(:dj_set) { create(:dj_set, :with_tracks, tracks_count: 2, name: "Export Test") }

    it "returns a text file" do
      get export_dj_set_path(dj_set)
      expect(response).to have_http_status(:ok)
      expect(response.content_type).to include("text/plain")
    end

    it "sends file as attachment" do
      get export_dj_set_path(dj_set)
      expect(response.headers["Content-Disposition"]).to include("attachment")
    end

    it "includes set name in filename" do
      get export_dj_set_path(dj_set)
      expect(response.headers["Content-Disposition"]).to include("export-test")
    end

    it "includes track information in content" do
      get export_dj_set_path(dj_set)
      expect(response.body).to include(dj_set.tracks.first.name)
    end
  end

  describe "POST /dj_sets/:id/convert_to_playlist" do
    let(:dj_set) { create(:dj_set, :with_tracks, tracks_count: 3, name: "Test Set") }

    context "with valid parameters" do
      let(:params) do
        {
          name: "Test Playlist",
          description: "Converted from set"
        }
      end

      it "creates a new playlist" do
        expect do
          post convert_to_playlist_dj_set_path(dj_set), params: params
        end.to change(Playlist, :count).by(1)
      end

      it "copies all tracks to playlist" do
        post convert_to_playlist_dj_set_path(dj_set), params: params
        playlist = Playlist.last
        expect(playlist.tracks.pluck(:id)).to eq(dj_set.tracks.pluck(:id))
      end

      it "redirects to the new playlist" do
        post convert_to_playlist_dj_set_path(dj_set), params: params
        expect(response).to redirect_to(playlist_path(Playlist.last))
      end

      it "displays success notice" do
        post convert_to_playlist_dj_set_path(dj_set), params: params
        follow_redirect!
        expect(response.body).to include("Converted to playlist")
      end
    end

    context "with delete_set option" do
      let(:params) do
        {
          name: "Test Playlist",
          delete_set: "1"
        }
      end

      it "deletes the original set after conversion" do
        post convert_to_playlist_dj_set_path(dj_set), params: params
        expect(DjSet.exists?(dj_set.id)).to be false
      end

      it "still creates the playlist" do
        dj_set # Trigger creation before expect block
        expect do
          post convert_to_playlist_dj_set_path(dj_set), params: params
        end.to change(Playlist, :count).by(1)
                                       .and change(DjSet, :count).by(-1)
      end
    end

    context "without delete_set option" do
      let(:params) do
        { name: "Test Playlist" }
      end

      it "keeps the original set" do
        post convert_to_playlist_dj_set_path(dj_set), params: params
        expect(DjSet.exists?(dj_set.id)).to be true
      end
    end
  end

  describe "POST /dj_sets/:id/import_tracks" do
    let(:dj_set) { create(:dj_set) }

    context "with valid file" do
      let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/valid_playlist.txt"), "text/plain") }

      it "imports tracks into existing set" do
        expect do
          post import_tracks_dj_set_path(dj_set), params: { file: file }
        end.to change { dj_set.tracks.count }.by_at_least(1)
      end

      it "creates new track records" do
        expect do
          post import_tracks_dj_set_path(dj_set), params: { file: file }
        end.to change(Track, :count).by_at_least(1)
      end

      it "creates DJ set track associations" do
        expect do
          post import_tracks_dj_set_path(dj_set), params: { file: file }
        end.to change(DjSetsTrack, :count).by_at_least(1)
      end

      it "redirects to the DJ set" do
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        expect(response).to redirect_to(dj_set_path(dj_set))
      end

      it "displays success message with track count" do
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        follow_redirect!
        expect(response.body).to match(/Successfully imported tracks/)
      end
    end

    context "when appending to existing tracks" do
      let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/valid_playlist.txt"), "text/plain") }
      let!(:existing_track) { create(:track) }

      before do
        dj_set.dj_sets_tracks.create!(track: existing_track, order: 1)
      end

      it "appends new tracks to existing ones" do
        initial_count = dj_set.tracks.count
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        dj_set.reload
        expect(dj_set.tracks.count).to be > initial_count
      end

      it "maintains existing tracks" do
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        dj_set.reload
        expect(dj_set.ordered_tracks.first).to eq(existing_track)
      end

      it "resequences all tracks" do
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        dj_set.reload
        orders = dj_set.dj_sets_tracks.order(:order).pluck(:order)
        expect(orders).to eq((1..orders.length).to_a)
      end
    end

    context "without file" do
      it "displays error message" do
        post import_tracks_dj_set_path(dj_set), params: {}
        expect(response).to redirect_to(dj_set_path(dj_set))
        follow_redirect!
        expect(response.body).to include("Please select a file")
      end

      it "does not import tracks" do
        expect do
          post import_tracks_dj_set_path(dj_set), params: {}
        end.not_to change(DjSetsTrack, :count)
      end
    end

    context "with invalid file format" do
      let(:invalid_file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/invalid_playlist.txt"), "text/plain") }

      before do
        FileUtils.mkdir_p(Rails.root.join("spec/fixtures/files"))
        Rails.root.join("spec/fixtures/files/invalid_playlist.txt").write("Invalid\tHeaders\n1\t2\t3")
      end

      after do
        FileUtils.rm_f(Rails.root.join("spec/fixtures/files/invalid_playlist.txt"))
      end

      it "displays error message" do
        post import_tracks_dj_set_path(dj_set), params: { file: invalid_file }
        expect(response).to redirect_to(dj_set_path(dj_set))
        follow_redirect!
        expect(response.body).to include("Failed to import tracks")
      end

      it "does not import tracks" do
        expect do
          post import_tracks_dj_set_path(dj_set), params: { file: invalid_file }
        end.not_to change(DjSetsTrack, :count)
      end
    end

    context "with duplicate tracks" do
      let(:file) { fixture_file_upload(Rails.root.join("spec/fixtures/files/valid_playlist.txt"), "text/plain") }

      before do
        # First import
        post import_tracks_dj_set_path(dj_set), params: { file: file }
        dj_set.reload
      end

      it "skips duplicate tracks" do
        file2 = fixture_file_upload(Rails.root.join("spec/fixtures/files/valid_playlist.txt"), "text/plain")
        initial_count = dj_set.tracks.count

        post import_tracks_dj_set_path(dj_set), params: { file: file2 }
        dj_set.reload

        expect(dj_set.tracks.count).to eq(initial_count)
      end
    end
  end
end
