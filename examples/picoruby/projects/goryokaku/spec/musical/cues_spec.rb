# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Musical::Cues do
  it "defines the directional five-step shake shimmer" do
    right = described_class.shake(:right, 100)
    left = described_class.shake(:left, 100)

    expect(right.map { |cue| cue[1] }).to eq([4_200, 6_500, 5_200, 7_400, 4_600])
    expect(left.map { |cue| cue[1] }).to eq([4_600, 7_400, 5_200, 6_500, 4_200])
    expect(right.map { |cue| cue[3] }).to eq([1.0, 0.82, 0.66, 0.48, 0.30])
    expect(right.map { |cue| cue[0] }).to eq([0, 20, 40, 60, 80])
  end

  it "defines the sharp six-step strike shimmer" do
    cues = described_class.strike(120)

    expect(cues.map { |cue| cue[1] }).to eq([5_200, 7_800, 4_600, 6_900, 4_100, 5_800])
    expect(cues.map { |cue| cue[3] }).to eq([1.0, 0.90, 0.76, 0.60, 0.44, 0.28])
    expect(cues.map { |cue| cue[0] }).to eq([0, 20, 40, 60, 80, 100])
  end

  it "rejects unknown notes, axes, and shake directions" do
    expect { described_class.frequency("H4") }.to raise_error(ArgumentError, /unknown note/)
    expect { described_class.motion(:unknown) }.to raise_error(ArgumentError, /unknown motion axis/)
    expect { described_class.shake(:unknown, 100) }.to raise_error(ArgumentError, /unknown shake direction/)
  end
end
