# frozen_string_literal: true

FactoryBot.define do
  factory :playlists_track do
    playlist
    track
    sequence(:order) { |n| n }
  end
end
