class MigrateTrackKeysToKeys < ActiveRecord::Migration[7.1]
  def up
    # Create keys for existing unique key values in tracks
    existing_keys = Track.distinct.pluck(:key).compact
    existing_keys.each do |key_name|
      Key.create!(name: key_name)
    end

    # Associate existing tracks with the newly created keys
    Track.find_each do |track|
      if track.key.present?
        key = Key.find_by(name: track.key)
        track.update!(key_id: key.id)
      end
    end

    # Rename the old key column to old_key
    rename_column :tracks, :key, :old_key
  end

  def down
    # Rename old_key back to key
    rename_column :tracks, :old_key, :key

    # Remove key_id column from tracks
    remove_column :tracks, :key_id
  end
end
