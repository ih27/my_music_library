# frozen_string_literal: true

require "rails_helper"

RSpec.describe Key, type: :model do
  describe "associations" do
    it { is_expected.to have_many(:tracks) }
  end

  describe "#compatible_keys" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:key_7a) { create(:key, :camelot_7a) }
    let(:key_9a) { create(:key, :camelot_9a) }
    let(:key_3a) { create(:key, :camelot_3a) }

    context "with :same level" do
      it "returns only the same key" do
        compatible = key_8a.compatible_keys(level: :same)
        expect(compatible).to contain_exactly(key_8a)
      end
    end

    context "with :smooth level" do
      it "returns keys for smooth transitions" do
        compatible = key_8a.compatible_keys(level: :smooth)
        expect(compatible).to include(key_8b, key_7a, key_9a)
        expect(compatible).not_to include(key_8a) # :smooth excludes the same key
      end
    end

    context "with :energy_boost level" do
      it "returns keys for energy boost transitions" do
        compatible = key_8a.compatible_keys(level: :energy_boost)
        expect(compatible).to include(key_3a)
      end
    end

    context "with :all level" do
      it "returns all compatible keys" do
        compatible = key_8a.compatible_keys(level: :all)
        expect(compatible).to include(key_8a, key_8b, key_7a, key_9a, key_3a)
      end
    end
  end

  describe "#transition_quality_to" do
    let(:key_8a) { create(:key, :camelot_8a) }
    let(:key_8b) { create(:key, :camelot_8b) }
    let(:key_7a) { create(:key, :camelot_7a) }

    it "returns :perfect for same key" do
      expect(key_8a.transition_quality_to(key_8a)).to eq(:perfect)
    end

    it "returns :smooth for relative major/minor" do
      expect(key_8a.transition_quality_to(key_8b)).to eq(:smooth)
    end

    it "returns :smooth for adjacent keys" do
      expect(key_8a.transition_quality_to(key_7a)).to eq(:smooth)
    end

    it "returns :rough for nil key" do
      expect(key_8a.transition_quality_to(nil)).to eq(:rough)
    end
  end
end
