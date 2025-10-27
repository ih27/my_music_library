# frozen_string_literal: true

require "rails_helper"

RSpec.describe CamelotWheelService do
  describe ".parse_key" do
    it "parses valid Camelot notation" do
      result = described_class.parse_key("8A")
      expect(result).to eq({ position: 8, mode: "A" })
    end

    it "parses all positions (1-12)" do
      (1..12).each do |position|
        result = described_class.parse_key("#{position}A")
        expect(result[:position]).to eq(position)
      end
    end

    it "parses both modes (A and B)" do
      expect(described_class.parse_key("8A")[:mode]).to eq("A")
      expect(described_class.parse_key("8B")[:mode]).to eq("B")
    end

    it "returns nil for invalid notation" do
      expect(described_class.parse_key("invalid")).to be_nil
      expect(described_class.parse_key("13A")).to be_nil
      expect(described_class.parse_key("0A")).to be_nil
      expect(described_class.parse_key("8C")).to be_nil
    end

    it "returns nil for nil input" do
      expect(described_class.parse_key(nil)).to be_nil
    end
  end

  describe ".compatible_keys" do
    context "with :same level" do
      it "returns only the same key" do
        keys = described_class.compatible_keys("8A", level: :same)
        expect(keys).to eq(["8A"])
      end
    end

    context "with :smooth level" do
      it "returns adjacent positions" do
        keys = described_class.compatible_keys("8A", level: :smooth)
        expect(keys).to include("7A", "9A")
      end

      it "returns relative major/minor" do
        keys = described_class.compatible_keys("8A", level: :smooth)
        expect(keys).to include("8B")
      end

      it "wraps around the wheel (12 to 1)" do
        keys = described_class.compatible_keys("12A", level: :smooth)
        expect(keys).to include("11A", "1A")
      end

      it "wraps around the wheel (1 to 12)" do
        keys = described_class.compatible_keys("1A", level: :smooth)
        expect(keys).to include("12A", "2A")
      end
    end

    context "with :energy_boost level" do
      it "returns key 7 positions forward" do
        keys = described_class.compatible_keys("8A", level: :energy_boost)
        expect(keys).to include("3A")
      end

      it "wraps correctly for energy boost" do
        keys = described_class.compatible_keys("10A", level: :energy_boost)
        expect(keys).to include("5A")
      end
    end

    context "with :all level" do
      it "returns all compatible keys" do
        keys = described_class.compatible_keys("8A", level: :all)
        expect(keys).to include("8A", "7A", "9A", "8B", "3A")
      end

      it "returns unique keys only" do
        keys = described_class.compatible_keys("8A", level: :all)
        expect(keys.size).to eq(keys.uniq.size)
      end
    end

    it "returns empty array for invalid key" do
      expect(described_class.compatible_keys("invalid")).to eq([])
      expect(described_class.compatible_keys(nil)).to eq([])
    end
  end

  describe ".transition_quality" do
    it "returns :perfect for same key" do
      expect(described_class.transition_quality("8A", "8A")).to eq(:perfect)
    end

    it "returns :smooth for adjacent positions" do
      expect(described_class.transition_quality("8A", "7A")).to eq(:smooth)
      expect(described_class.transition_quality("8A", "9A")).to eq(:smooth)
    end

    it "returns :smooth for relative major/minor" do
      expect(described_class.transition_quality("8A", "8B")).to eq(:smooth)
      expect(described_class.transition_quality("8B", "8A")).to eq(:smooth)
    end

    it "returns :energy_boost for +7 positions" do
      expect(described_class.transition_quality("8A", "3A")).to eq(:energy_boost)
    end

    it "returns :rough for incompatible transitions" do
      expect(described_class.transition_quality("8A", "1A")).to eq(:rough)
      expect(described_class.transition_quality("8A", "5B")).to eq(:rough)
    end

    it "returns :rough for nil keys" do
      expect(described_class.transition_quality(nil, "8A")).to eq(:rough)
      expect(described_class.transition_quality("8A", nil)).to eq(:rough)
    end

    it "returns :rough for invalid keys" do
      expect(described_class.transition_quality("invalid", "8A")).to eq(:rough)
      expect(described_class.transition_quality("8A", "invalid")).to eq(:rough)
    end
  end

  describe ".harmonic_flow_score" do
    it "returns 100 for empty transitions" do
      expect(described_class.harmonic_flow_score([])).to eq(100.0)
    end

    it "returns 100 for all perfect transitions" do
      transitions = [
        { quality: :perfect },
        { quality: :perfect },
        { quality: :perfect }
      ]
      expect(described_class.harmonic_flow_score(transitions)).to eq(100.0)
    end

    it "returns correct score for mixed transitions" do
      transitions = [
        { quality: :perfect },  # 3 points
        { quality: :smooth },   # 2 points
        { quality: :rough }     # 0 points
      ]
      # Total: 5 points / Max: 9 points = 55.6%
      expect(described_class.harmonic_flow_score(transitions)).to eq(55.6)
    end

    it "returns 0 for all rough transitions" do
      transitions = [
        { quality: :rough },
        { quality: :rough }
      ]
      expect(described_class.harmonic_flow_score(transitions)).to eq(0.0)
    end

    it "gives equal weight to smooth and energy_boost" do
      smooth_transitions = [{ quality: :smooth }]
      energy_transitions = [{ quality: :energy_boost }]
      expect(described_class.harmonic_flow_score(smooth_transitions))
        .to eq(described_class.harmonic_flow_score(energy_transitions))
    end
  end

  describe ".indicator" do
    it "returns correct emoji for each quality" do
      expect(described_class.indicator(:perfect)).to eq("🟢")
      expect(described_class.indicator(:smooth)).to eq("🔵")
      expect(described_class.indicator(:energy_boost)).to eq("⚡")
      expect(described_class.indicator(:rough)).to eq("🟡")
    end

    it "returns rough indicator for unknown quality" do
      expect(described_class.indicator(:unknown)).to eq("🟡")
    end
  end
end
