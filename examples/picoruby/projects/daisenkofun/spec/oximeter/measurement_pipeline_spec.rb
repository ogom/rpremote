# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe "Daisen Kofun oximeter measurement contracts" do
  it "uses hysteresis for finger arrival and removal" do
    detector = Daisenkofun::Oximeter::Measurement::FingerDetector.new(threshold: 20_000, hysteresis: 1_000)

    expect(detector.update(20_500)).to be_nil
    expect(detector.update(21_001)).to eq(:detected)
    expect(detector.update(19_500)).to be_nil
    expect(detector.update(18_999)).to eq(:removed)
  end

  it "emits finger events and clears published measurement values on removal" do
    events = []
    subscriber = ->(event, payload) { events << [event, payload] }
    dispatcher = Daisenkofun::Oximeter::Dispatcher.new.subscribe(subscriber)
    processor = Daisenkofun::Oximeter::Measurement::Processor.new(dispatcher: dispatcher)

    processor.process_sample(red: 30_000, ir: 30_000, timestamp_ms: 100)
    processor.process_sample(red: 10_000, ir: 10_000, timestamp_ms: 200)

    expect(events.map(&:first)).to eq(%i[finger_detected finger_removed])
    expect([processor.latest_bpm, processor.latest_spo2]).to eq([0.0, 0.0])
  end

  it "derives a normalized half-height pulse width only after two valid boundaries" do
    extractor = Daisenkofun::Oximeter::Measurement::PulseShapeExtractor.new(min_samples: 8, min_amplitude: 100)
    8.times { |index| extractor.push([300, 250, 150, 100, 100, 150, 250, 300][index]) }
    expect(extractor.finish(800)).to be_nil

    8.times { |index| extractor.push([300, 250, 150, 100, 100, 150, 250, 300][index]) }
    pulse = extractor.finish(800)

    expect(pulse[:pulse_width_ratio]).to eq(0.5)
    expect(pulse).to include(pulse_width_ms: 400, pulse_amplitude: 200, pulse_samples: 8)
  end
end
