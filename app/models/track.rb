class Track < ApplicationRecord
  belongs_to :key, optional: true
  has_many :playlists_tracks, dependent: :destroy
  has_many :playlists, through: :playlists_tracks
  has_and_belongs_to_many :artists

  validates :name, :bpm, :date_added, presence: true
  validates :key, presence: true, unless: -> { key_id.nil? }
end
