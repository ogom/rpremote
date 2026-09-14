# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Oximeter::Measurement::RollingSampleWindow do
  it "requires a positive Integer capacity" do
    [0, -1, 1.5].each do |capacity|
      expect { described_class.new(capacity) }.to raise_error(ArgumentError)
    end
  end

  it "retains only the newest values at capacity" do
    window = described_class.new(3)
    [1, 2, 3, 7].each { |value| window.push(value) }

    expect(window.count).to eq(3)
    expect(window.average).to eq(4.0)
  end

  it "calculates population standard deviation and resets state" do
    window = described_class.new(4)
    [2, 4, 4, 4].each { |value| window.push(value) }

    expect(window.standard_deviation).to be_within(0.0001).of(Math.sqrt(0.75))
    expect(window.clear).to equal(window)
    expect([window.count, window.average, window.standard_deviation]).to eq([0, 0.0, 0.0])
  end
end
