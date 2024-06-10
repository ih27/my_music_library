class Track < ApplicationRecord
  has_many :playlists_tracks, dependent: :destroy
  has_many :playlists, through: :playlists_tracks
  has_and_belongs_to_many :artists

  validates :name, :key, :bpm, :date_added, presence: true
end
