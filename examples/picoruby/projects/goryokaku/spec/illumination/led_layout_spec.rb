# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Illumination::LedLayout do
  it "assigns all 380 LEDs exactly once across the star, ravelin, and outer perimeter" do
    zones = [described_class::STAR, described_class::RAVELIN, described_class::OUTER]
    addresses = zones.flat_map { |zone| described_class.zone_order(zone) }

    expect(zones.map { |zone| described_class.zone_order(zone).length }).to eq([170, 20, 190])
    expect(addresses).to eq((0...380).to_a)
    expect(addresses.uniq.length).to eq(described_class::LED_COUNT)
  end

  it "covers the star once with ten contiguous physical segments" do
    segments = described_class::STAR_SEGMENT_RANGES.map { |range| described_class.range_indices(range) }

    expect(segments.map(&:length)).to eq([17, 17, 17, 17, 17, 17, 17, 16, 17, 18])
    expect(segments.flatten).to eq(described_class.star_order)
  end

  it "starts musical traversal at group five and reverses radial B edges" do
    expect(described_class.musical_groups(:right).first).to eq(described_class.star_group(4))
    expect(described_class.musical_groups(:left).first).to eq(described_class.star_group(4))
    expect(described_class.star_rays[0]).to eq((0..16).to_a)
    expect(described_class.star_rays[1]).to eq((17..33).to_a.reverse)
  end

  it "wraps outer-perimeter traversal at the physical ring seam" do
    order = described_class.outer_order(189)

    expect(order.first(3)).to eq([379, 190, 191])
    expect(order.length).to eq(190)
    expect(order.uniq.length).to eq(190)
  end
end
