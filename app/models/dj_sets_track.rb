# frozen_string_literal: true

class DjSetsTrack < ApplicationRecord
  self.table_name = "dj_sets_tracks"

  belongs_to :dj_set
  belongs_to :track

  validates :order, presence: true, numericality: { only_integer: true, greater_than: 0 }
  validates :track_id, uniqueness: { scope: :dj_set_id, message: "already in set" }

  # Reorder tracks within a set based on provided track ID array
  #
  # @param dj_set_id [Integer] ID of the set
  # @param track_ids_in_order [Array<Integer>] Array of track IDs in desired order
  # @return [void]
  def self.reorder_tracks(dj_set_id, track_ids_in_order)
    transaction do
      track_ids_in_order.each_with_index do |track_id, index|
        where(dj_set_id: dj_set_id, track_id: track_id)
          .update_all(order: index + 1)
      end
    end
  end
end
