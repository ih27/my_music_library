# frozen_string_literal: true

FactoryBot.define do
  factory :playlist do
    name { Faker::Music::RockBand.name }

    trait :with_tracks do
      transient do
        tracks_count { 5 }
      end

      after(:create) do |playlist, evaluator|
        tracks = create_list(:track, evaluator.tracks_count, :with_artists)
        tracks.each_with_index do |track, index|
          PlaylistsTrack.create!(playlist: playlist, track: track, order: index + 1)
        end
      end
    end

    trait :with_harmonic_flow do
      after(:create) do |playlist|
        # Create tracks with compatible keys for good harmonic flow
        key_8a = create(:key, :camelot_8a)
        key_8b = create(:key, :camelot_8b)
        key_9a = create(:key, :camelot_9a)

        tracks = [
          create(:track, :with_artists, key: key_8a),
          create(:track, :with_artists, key: key_8a), # Perfect transition
          create(:track, :with_artists, key: key_8b), # Smooth transition (relative)
          create(:track, :with_artists, key: key_9a)  # Smooth transition (+1)
        ]

        tracks.each_with_index do |track, index|
          PlaylistsTrack.create!(playlist: playlist, track: track, order: index + 1)
        end
      end
    end
  end
end
