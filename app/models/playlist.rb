class Playlist < ApplicationRecord
  has_many :playlists_tracks, dependent: :destroy
  has_many :tracks, through: :playlists_tracks
  has_one_attached :cover_art

  validates :name, presence: true

  after_create :attach_default_cover_art

  def unique_identifier
    tracks.order(:id).pluck(:id).join('-')
  end

  private

  def attach_default_cover_art
    unless cover_art.attached?
      cover_art.attach(
        io: File.open(Rails.root.join('app', 'assets', 'images', 'default_cover_art.jpg')),
        filename: 'default_cover_art.jpg',
        content_type: 'image/jpg'
      )
    end
  end
end
