class Artist < ApplicationRecord
  has_and_belongs_to_many :tracks

  validates :name, presence: true

  before_destroy :check_tracks

  private

  def check_tracks
    throw(:abort) if tracks.exists?
  end
end
