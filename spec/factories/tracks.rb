# frozen_string_literal: true

FactoryBot.define do
  factory :track do
    name { Faker::Music::RockBand.song }
    bpm { Faker::Number.between(from: 90, to: 140) }
    time { Faker::Number.between(from: 180, to: 300) }
    album { Faker::Music.album }
    date_added { Faker::Date.between(from: 1.year.ago, to: Time.zone.today) }
    key

    trait :with_artists do
      after(:create) do |track|
        create_list(:artist, 2, tracks: [track])
      end
    end

    trait :without_key do
      key { nil }
    end

    trait :house_tempo do
      bpm { 128.0 }
    end

    trait :techno_tempo do
      bpm { 130.0 }
    end
  end
end
