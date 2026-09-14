# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Oximeter measurement detectors" do
  it "uses strict hysteresis boundaries for finger arrival and removal" do
    detector = Oximeter::Measurement::FingerDetector.new(threshold: 20_000, hysteresis: 1_000)

    expect(detector.update(21_000)).to be_nil
    expect(detector.update(21_001)).to eq(:detected)
    expect(detector.update(19_000)).to be_nil
    expect(detector.update(18_999)).to eq(:removed)
  end

  it "waits for its baseline and stabilization period before reporting a beat" do
    detector = beat_detector(stabilize_ms: 500)
    detector.start(0)

    expect(detector.process_sample(ir: 100, timestamp_ms: 0)).to be_nil
    expect(detector.process_sample(ir: 200, timestamp_ms: 100)).to be_nil
    expect(detector.process_sample(ir: 0, timestamp_ms: 499)).to be_nil
  end

  it "accepts only beat intervals strictly inside the configured range" do
    expect(crossing_at(500)).to eq(interval_ms: 500, accepted: true)
    expect(crossing_at(350)).to eq(interval_ms: 350, accepted: false)
    expect(crossing_at(1_500)).to eq(interval_ms: 1_500, accepted: false)
  end

  def beat_detector(stabilize_ms: 0)
    Oximeter::Measurement::BeatDetector.new(
      smooth_samples: 1, baseline_samples: 2, hysteresis: 10,
      min_interval_ms: 350, max_interval_ms: 1_500, stabilize_ms: stabilize_ms
    )
  end

  def crossing_at(timestamp_ms)
    detector = beat_detector
    detector.start(0)
    detector.process_sample(ir: 100, timestamp_ms: 0)
    detector.process_sample(ir: 200, timestamp_ms: 100)
    detector.process_sample(ir: 0, timestamp_ms: timestamp_ms)
  end
end
