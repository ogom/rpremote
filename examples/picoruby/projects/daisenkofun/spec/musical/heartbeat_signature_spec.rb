# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Musical::Planners::HeartbeatSignature do
  def beat(index, interval: 800, ratio: 0.5)
    at = index * 800
    { timestamp_ms: at, interval_ms: interval, pulse_width_ratio: ratio }
  end

  def signature(planner, intervals, ratios, spo2_values)
    intervals.each_with_index.map do |interval, index|
      at = 1_000 + (index * 900)
      planner.measurement(timestamp_ms: at, spo2: spo2_values[index])
      planner.plan({ timestamp_ms: at, interval_ms: interval, pulse_width_ratio: ratios[index] }, at)
    end.last
  end

  it "uses the canon for seven beats and replaces the eighth with eight signature notes" do
    planner = described_class.new
    7.times do |index|
      expect(planner.plan(beat(index), index * 800).length).to eq(3)
    end

    signature = planner.plan(beat(7), 5_600)

    expect(signature.length).to eq(8)
    expect(signature.map { |cue| cue[:source] }.uniq).to eq([:heartbeat_signature])
    expect(signature.map { |cue| cue[:moat] }).to eq(%i[inner middle outer inner middle outer inner middle])
    expect(planner.signature_count).to eq(1)
    expect(planner.plan(beat(8), 6_400).length).to eq(3)
  end

  it "discards a partial signature on reset without erasing the completed-run count" do
    planner = described_class.new
    8.times { |index| planner.plan(beat(index), index * 800) }
    7.times { |index| planner.plan(beat(index + 8), (index + 8) * 800) }
    planner.reset

    expect(planner.signature_count).to eq(1)
    expect(planner.plan(beat(20), 16_000).length).to eq(3)
  end

  it "derives a deterministic signature from interval, SpO2, and pulse width" do
    intervals = [820, 780, 760, 840, 800, 740, 860, 790]
    ratios = [0.20, 0.25, 0.30, 0.35, 0.40, 0.45, 0.50, 0.55]
    spo2_values = [97.0, 97.2, 97.7, 97.8, 97.4, 96.3, 96.2, 97.0]
    fields = %i[frequency_hz duration_ms duty_percent moat]

    first = signature(described_class.new, intervals, ratios, spo2_values)
    second = signature(described_class.new, intervals, ratios, spo2_values)

    expect(first.map { |cue| cue.values_at(*fields) }).to eq(second.map { |cue| cue.values_at(*fields) })
    expect(first.map { |cue| cue[:frequency_hz] }.uniq.length).to be > 1
    expect(first.map { |cue| cue[:duration_ms] }.uniq.length).to be > 1
    expect(first.map { |cue| cue[:duty_percent] }.uniq.length).to be > 1
  end
end
