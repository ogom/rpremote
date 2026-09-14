# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Musical::TambourineDetector do
  def detector(mode = :musical)
    described_class.new(
      application_mode: mode, orientation_stable_ms: 100,
      shake_threshold: 0.2, shake_window_ms: 250, shake_reversals: 2, shake_retrigger_ms: 100,
      strike_threshold: 0.45, strike_release_threshold: 0.15, strike_retrigger_ms: 120
    )
  end

  def sample(target, now, z_axis)
    target.on_event([:motion_sample, now, [0.0, 1.0, z_axis], [0.0, 0.0, 0.0]])
  end

  def ready(target, at: 0)
    target.on_event(%i[orientation_changed y_up])
    sample(target, at, 0.0)
    sample(target, at + 100, 0.0)
  end

  it "requires a stable Y-up orientation before recognizing a gesture" do
    target = detector
    target.on_event(%i[orientation_changed y_up])

    expect(sample(target, 0, 0.0)).to be_nil
    expect(sample(target, 99, 0.8)).to be_nil
  end

  it "recognizes two smooth Z-axis reversals as a directional shake" do
    target = detector
    ready(target)
    [0.32, 0.10, -0.10, -0.32, -0.10, 0.10].each_with_index do |z, index|
      sample(target, 120 + (index * 20), z)
    end

    expect(sample(target, 240, 0.32)).to eq([:tambourine_shaken, 240, 0.6, :right, 100])
  end

  it "recognizes Z-axis jerk as one strike and waits for release and retrigger" do
    target = detector
    ready(target)

    event = sample(target, 120, 0.5625)
    expect([event[0], event[1], event[3]]).to eq([:tambourine_struck, 120, 120])
    expect(event[2]).to be_within(0.0001).of(0.25)
    expect(sample(target, 140, 1.125)).to be_nil
    expect(sample(target, 160, 1.125)).to be_nil
    expect(sample(target, 260, 1.0)).to be_nil
  end

  it "waits for tambourine confirmation in combined mode and becomes inactive away from Y-up" do
    target = detector(:combined)
    ready(target)
    expect(sample(target, 120, 0.5625)).to be_nil

    target.on_event(%i[mode_changed tambourine])
    ready(target, at: 140)
    expect(sample(target, 260, 0.5625)&.first).to eq(:tambourine_struck)
    expect(target.on_event(%i[orientation_changed z_up])).to eq([:tambourine_inactive])
  end
end
