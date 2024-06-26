class Track < ApplicationRecord
  belongs_to :key, optional: true
  has_many :playlists_tracks, dependent: :destroy
  has_many :playlists, through: :playlists_tracks
  has_and_belongs_to_many :artists
  has_one_attached :audio_file

  validates :name, :bpm, :date_added, presence: true
  validates :key, presence: true, unless: -> { key_id.nil? }
  validates :audio_file, presence: true, blob: { content_type: :audio }, if: -> { audio_file.attached? }

  def self.search(query)
    query = "%#{query.downcase}%"
    joins(:artists, :key, :playlists).where(
      'LOWER(tracks.name) LIKE ? OR LOWER(tracks.bpm) LIKE ? OR LOWER(artists.name) LIKE ? OR LOWER(keys.name) LIKE ? OR LOWER(playlists.name) LIKE ?',
      query, query, query, query, query
    ).distinct
  end
end
