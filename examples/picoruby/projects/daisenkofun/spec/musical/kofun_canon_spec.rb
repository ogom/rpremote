# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Musical::Planners::KofunCanon do
  it "turns one beat into three sequential inner, middle, and outer moat cues" do
    cues = described_class.new.plan({ timestamp_ms: 1_000, interval_ms: 900 }, 1_000)

    expect(cues.map { |cue| cue[:moat] }).to eq(%i[inner middle outer])
    expect(cues.map { |cue| cue[:due_ms] }).to eq([1_000, 1_300, 1_600])
    expect(cues.map { |cue| cue[:frequency_hz] }).to eq([294, 392, 523])
    expect(cues.map { |cue| cue[:duty_percent] }).to eq([3.4, 3.0, 2.6])
  end

  it "reverses travel when the next interval grows by at least 40 ms" do
    planner = described_class.new
    planner.plan({ timestamp_ms: 1_000, interval_ms: 900 }, 1_000)
    cues = planner.plan({ timestamp_ms: 1_900, interval_ms: 940 }, 1_900)

    expect(cues.first[:travel_direction]).to eq(-1)
    expect(cues.map { |cue| cue[:moat] }).to eq(%i[outer inner middle])
  end

  it "resets traversal and collected SpO2 state" do
    planner = described_class.new
    planner.plan({ timestamp_ms: 1_000, interval_ms: 900 }, 1_000)
    planner.reset

    expect(planner.plan({ timestamp_ms: 2_000, interval_ms: 900 }, 2_000).map { |cue| cue[:moat] }).to eq(%i[inner middle outer])
  end
end
