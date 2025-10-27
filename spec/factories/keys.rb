# frozen_string_literal: true

FactoryBot.define do
  factory :key do
    sequence(:name) { |n| "#{(n % 12) + 1}#{%w[A B].sample}" }

    # Specific Camelot keys for testing
    trait :camelot_8a do
      name { "8A" }
    end

    trait :camelot_8b do
      name { "8B" }
    end

    trait :camelot_7a do
      name { "7A" }
    end

    trait :camelot_9a do
      name { "9A" }
    end

    trait :camelot_3a do
      name { "3A" }
    end
  end
end
