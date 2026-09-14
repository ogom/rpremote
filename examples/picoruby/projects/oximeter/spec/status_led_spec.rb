# frozen_string_literal: true

require_relative "spec_helper"

RSpec.describe "Oximeter status LED presentation" do
  it "translates measurement events into state rendered on the next tick" do
    renderer = OximeterSpec::Renderer.new
    presenter = Oximeter::StatusLed::Presenter.new(renderer)

    presenter.call(:finger_detected, timestamp_ms: 10, ir: 30_000)
    presenter.call(:beat, timestamp_ms: 500, bpm: 72.0)
    presenter.call(:measurement_completed, timestamp_ms: 500, bpm: 72.0, spo2: 98.0)
    presenter.tick(520)

    expect(renderer.frames).to eq([[:result, 520, { spo2: 98.0, bpm: 72.0, last_beat_at: 500 }]])
  end

  it "returns to the waiting state and clears result values on finger removal" do
    renderer = OximeterSpec::Renderer.new
    presenter = Oximeter::StatusLed::Presenter.new(renderer)
    presenter.call(:measurement_completed, timestamp_ms: 500, bpm: 72.0, spo2: 98.0)

    presenter.call(:finger_removed, timestamp_ms: 600, ir: 10_000).tick(700)

    expect(renderer.frames.last).to eq([:no_finger, 700, { spo2: 0.0, bpm: 0.0, last_beat_at: 0 }])
  end

  it "throttles frames by mode and renders a three-pixel trail" do
    pixels = OximeterSpec::Pixels.new
    renderer = Oximeter::StatusLed::Renderer.new(pixels)

    renderer.render(:no_finger, 119, spo2: 0, bpm: 0, last_beat_at: 0)
    renderer.render(:no_finger, 120, spo2: 0, bpm: 0, last_beat_at: 0)

    expect(pixels.show_count).to eq(1)
    expect(pixels.values.count { |rgb| rgb != [0, 0, 0] }).to eq(3)
    expect(pixels.values[0]).to eq([6, 6, 6])
  end

  it "uses green and red result colors around the display-only SpO2 threshold" do
    green_pixels = OximeterSpec::Pixels.new
    red_pixels = OximeterSpec::Pixels.new
    Oximeter::StatusLed::Renderer.new(green_pixels).render(:result, 40, spo2: 97, bpm: 60, last_beat_at: 0)
    Oximeter::StatusLed::Renderer.new(red_pixels).render(:result, 40, spo2: 96.9, bpm: 60, last_beat_at: 0)

    expect(green_pixels.values).to include([0, 12, 3])
    expect(red_pixels.values).to include([12, 0, 0])
  end

  it "shows a red error state and clears every pixel during cleanup" do
    pixels = OximeterSpec::Pixels.new
    renderer = Oximeter::StatusLed::Renderer.new(pixels)

    expect(renderer.error).to equal(renderer)
    expect(pixels.values.uniq).to eq([[12, 0, 0]])
    expect(renderer.clear).to equal(renderer)
    expect(pixels.values.uniq).to eq([[0, 0, 0]])
  end
end
