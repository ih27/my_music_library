class CreateDjSetsTracks < ActiveRecord::Migration[8.1]
  def change
    create_table :dj_sets_tracks do |t|
      t.references :dj_set, null: false, foreign_key: true
      t.references :track, null: false, foreign_key: true
      t.integer :order, null: false

      t.timestamps
    end

    add_index :dj_sets_tracks, [:dj_set_id, :track_id], unique: true
    add_index :dj_sets_tracks, [:dj_set_id, :order]
  end
end
