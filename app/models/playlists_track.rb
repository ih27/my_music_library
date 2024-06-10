class PlaylistsTrack < ApplicationRecord
  self.table_name = 'playlists_tracks'

  belongs_to :playlist
  belongs_to :track

  validates :order, presence: true, uniqueness: { scope: :playlist_id }
end
