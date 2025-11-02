# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# This file is the source Rails uses to define your schema when running `bin/rails
# db:schema:load`. When creating a new database, `bin/rails db:schema:load` tends to
# be faster and is potentially less error prone than running all of your
# migrations from scratch. Old migrations may fail to apply correctly if those
# migrations use external dependencies or application code.
#
# It's strongly recommended that you check this file into your version control system.

ActiveRecord::Schema[8.1].define(version: 2025_10_28_155009) do
  create_table "active_storage_attachments", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.bigint "record_id", null: false
    t.string "record_type", null: false
    t.index ["blob_id"], name: "index_active_storage_attachments_on_blob_id"
    t.index ["record_type", "record_id", "name", "blob_id"], name: "index_active_storage_attachments_uniqueness", unique: true
  end

  create_table "active_storage_blobs", force: :cascade do |t|
    t.bigint "byte_size", null: false
    t.string "checksum"
    t.string "content_type"
    t.datetime "created_at", null: false
    t.string "filename", null: false
    t.string "key", null: false
    t.text "metadata"
    t.string "service_name", null: false
    t.index ["key"], name: "index_active_storage_blobs_on_key", unique: true
  end

  create_table "active_storage_variant_records", force: :cascade do |t|
    t.bigint "blob_id", null: false
    t.string "variation_digest", null: false
    t.index ["blob_id", "variation_digest"], name: "index_active_storage_variant_records_uniqueness", unique: true
  end

  create_table "artists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "artists_tracks", id: false, force: :cascade do |t|
    t.integer "artist_id", null: false
    t.integer "track_id", null: false
    t.index ["artist_id", "track_id"], name: "index_artists_tracks_on_artist_id_and_track_id"
    t.index ["track_id", "artist_id"], name: "index_artists_tracks_on_track_id_and_artist_id"
  end

  create_table "dj_sets", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.text "description"
    t.string "name", null: false
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_dj_sets_on_name", unique: true
  end

  create_table "dj_sets_tracks", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.integer "dj_set_id", null: false
    t.integer "order", null: false
    t.integer "track_id", null: false
    t.datetime "updated_at", null: false
    t.index ["dj_set_id", "order"], name: "index_dj_sets_tracks_on_dj_set_id_and_order"
    t.index ["dj_set_id", "track_id"], name: "index_dj_sets_tracks_on_dj_set_id_and_track_id", unique: true
    t.index ["dj_set_id"], name: "index_dj_sets_tracks_on_dj_set_id"
    t.index ["track_id"], name: "index_dj_sets_tracks_on_track_id"
  end

  create_table "keys", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name"
    t.datetime "updated_at", null: false
    t.index ["name"], name: "index_keys_on_name", unique: true
  end

  create_table "playlists", force: :cascade do |t|
    t.datetime "created_at", null: false
    t.string "name", null: false
    t.datetime "updated_at", null: false
  end

  create_table "playlists_tracks", force: :cascade do |t|
    t.integer "order"
    t.integer "playlist_id", null: false
    t.integer "track_id", null: false
    t.index ["playlist_id", "track_id"], name: "index_playlists_tracks_on_playlist_id_and_track_id"
    t.index ["track_id", "playlist_id"], name: "index_playlists_tracks_on_track_id_and_playlist_id"
  end

  create_table "tracks", force: :cascade do |t|
    t.string "album"
    t.decimal "bpm", precision: 5, scale: 2, null: false
    t.datetime "created_at", null: false
    t.date "date_added", null: false
    t.integer "key_id"
    t.string "name", null: false
    t.integer "time"
    t.datetime "updated_at", null: false
    t.index ["key_id"], name: "index_tracks_on_key_id"
  end

  add_foreign_key "active_storage_attachments", "active_storage_blobs", column: "blob_id"
  add_foreign_key "active_storage_variant_records", "active_storage_blobs", column: "blob_id"
  add_foreign_key "dj_sets_tracks", "dj_sets"
  add_foreign_key "dj_sets_tracks", "tracks"
end
