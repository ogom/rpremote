# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Oximeter::Measurement::Processor do
  it "publishes finger facts without depending on an LED component" do
    collector = OximeterSpec::Collector.new
    dispatcher = Oximeter::Dispatcher.new.subscribe(collector)
    processor = described_class.new(dispatcher: dispatcher)

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 100)
    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 200)

    expect(collector.events.map(&:first)).to eq(%i[finger_detected finger_removed])
    expect([processor.latest_bpm, processor.latest_spo2]).to eq([0.0, 0.0])
  end

  it "publishes beat, update, and one completion event with measurement payloads" do
    collector = OximeterSpec::Collector.new
    dispatcher = Oximeter::Dispatcher.new.subscribe(collector)
    processor = described_class.new(
      dispatcher: dispatcher,
      finger_detector: transition_detector,
      beat_detector: beat_detector,
      spo2_estimator: spo2_estimator,
      session: measurement_session
    )

    processor.process_sample(red: 31_000, ir: 32_000, timestamp_ms: 500)

    expect(collector.events.map(&:first)).to eq(%i[finger_detected beat measurement_updated measurement_completed])
    expect(collector.events.last[1]).to include(timestamp_ms: 500, bpm: 72.0, spo2: 98.0)
    expect([processor.latest_bpm, processor.latest_spo2]).to eq([72.0, 98.0])
  end

  def transition_detector
    instance_double(
      Oximeter::Measurement::FingerDetector,
      update: :detected,
      present?: true
    )
  end

  def beat_detector
    instance_double(
      Oximeter::Measurement::BeatDetector,
      start: nil,
      clear: nil,
      process_sample: { interval_ms: 833, accepted: true }
    )
  end

  def spo2_estimator
    instance_double(
      Oximeter::Measurement::SpO2Estimator,
      push: nil,
      clear: nil,
      count: 100,
      estimate: 98.0
    )
  end

  def measurement_session
    instance_double(
      Oximeter::Measurement::Session,
      clear: nil,
      record_beat: 72.0,
      record_spo2: { bpm: 72.0, spo2: 98.0, complete: true, completed_now: true }
    )
  end
end
