# frozen_string_literal: true

class Key < ApplicationRecord
  has_many :tracks

  # Find all keys compatible with this key
  #
  # @param level [Symbol] Compatibility level (:same, :smooth, :energy_boost, :all)
  # @return [ActiveRecord::Relation] Key records
  def compatible_keys(level: :all)
    key_names = CamelotWheelService.compatible_keys(name, level: level)
    Key.where(name: key_names)
  end

  # Determine transition quality to another key
  #
  # @param other_key [Key] Destination key
  # @return [Symbol] Quality: :perfect, :smooth, :energy_boost, or :rough
  def transition_quality_to(other_key)
    return :rough unless other_key

    CamelotWheelService.transition_quality(name, other_key.name)
  end
end
