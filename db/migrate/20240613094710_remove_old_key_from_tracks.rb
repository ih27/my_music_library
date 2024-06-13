class RemoveOldKeyFromTracks < ActiveRecord::Migration[7.1]
  def change
    remove_column :tracks, :old_key, :string
  end
end
