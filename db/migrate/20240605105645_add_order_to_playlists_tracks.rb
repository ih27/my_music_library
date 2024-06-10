class AddOrderToPlaylistsTracks < ActiveRecord::Migration[7.1]
  def change
    add_column :playlists_tracks, :order, :integer
  end
end
