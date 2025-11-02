# frozen_string_literal: true

FactoryBot.define do
  factory :dj_set do
    sequence(:name) { |n| "#{Faker::Music.genre} Set #{n}" }
    description { Faker::Lorem.sentence }

    trait :with_tracks do
      transient do
        tracks_count { 5 }
      end

      after(:create) do |dj_set, evaluator|
        tracks = create_list(:track, evaluator.tracks_count, :with_artists)
        tracks.each_with_index do |track, index|
          DjSetsTrack.create!(dj_set: dj_set, track: track, order: index + 1)
        end
      end
    end

    trait :with_harmonic_flow do
      after(:create) do |dj_set|
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
          DjSetsTrack.create!(dj_set: dj_set, track: track, order: index + 1)
        end
      end
    end
  end
end
