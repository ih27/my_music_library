class AddPrimaryKeyToPlaylistsTracks < ActiveRecord::Migration[7.1]
  def change
    add_column :playlists_tracks, :id, :primary_key
  end
end
