# frozen_string_literal: true

FactoryBot.define do
  factory :dj_sets_track do
    dj_set
    track
    sequence(:order)
  end
end
