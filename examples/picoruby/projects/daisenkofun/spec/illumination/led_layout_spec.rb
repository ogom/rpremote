# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Illumination::LedLayout do
  it "assigns every main-model LED exactly once and reserves two attached kofun LEDs" do
    main = described_class.main_order

    expect(main.length).to eq(570)
    expect(main.uniq.length).to eq(570)
    expect(main.sort).to eq((0..569).to_a)
    expect([described_class::CHAYAMA, described_class::DAIANJIYAMA]).to eq([570, 571])
    expect(described_class::LED_COUNT).to eq(572)
  end

  it "reverses outline order without changing wiring direction, and reverses north-south traversal" do
    expect(described_class.outside_to_inside_order).to eq(described_class::OUTLINE_ORDERS.reverse.flatten)
    expect(described_class.south_to_north_order).to eq(described_class.north_to_south_order.reverse)
    expect(described_class.north_to_south_order.sort).to eq((0..569).to_a)
  end

  it "keeps symmetric forepart pairs on opposite sides of the mound base" do
    left = described_class.left_order(described_class::MOUND_BASE)
    right = described_class.right_order(described_class::MOUND_BASE)
    pairs = described_class.symmetric_forepart_pairs

    expect(pairs.length).to eq(left.length)
    expect(pairs.flatten.uniq.length).to eq(left.length + right.length)
    expect(pairs.all? { |a, b| left.include?(a) && right.include?(b) }).to be(true)
  end
end
