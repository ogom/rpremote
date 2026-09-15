# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Interaction::Runner do
  let(:sample) { { acceleration: [0.0, 0.0, 1.0], gyroscope: [1.0, 2.0, 3.0] } }
  let(:device) do
    instance_double(Goryokaku::Interaction::Device, open: nil, close: nil, sample: sample, touch_state: 1)
  end
  let(:detector) { instance_double(Goryokaku::Interaction::Detector, prime: nil, detect: []) }
  let(:events) { [] }
  let(:dispatcher) { double(:dispatcher, publish: nil) }
  let(:logger) { GoryokakuSpec::Logger.new }
  let(:runner) do
    described_class.new(device: device, detector: detector, dispatcher: dispatcher, logger: logger,
                        heartbeat_interval_ms: 5_000)
  end

  before do
    allow(dispatcher).to receive(:publish) { |event| events << event }
    runner.start
  end

  it "alternates candidates in Y-up and confirms the selected mode in Z-up" do
    allow(detector).to receive(:detect).and_return(
      [%i[orientation_changed y_up], [:touch_pressed]],
      [[:touch_pressed]],
      [%i[orientation_changed z_up], [:touch_pressed]]
    )

    runner.tick(0)
    runner.tick(1)
    runner.tick(2)

    expect(events.grep(%i[mode_selected illumination])).to eq([%i[mode_selected illumination]])
    expect(events.grep(%i[mode_selected tambourine])).to eq([%i[mode_selected tambourine]])
    expect(events.grep(%i[mode_changed tambourine])).to eq([%i[mode_changed tambourine]])
    expect(logger.messages).to include(
      "GORYOKAKU event=touch action=select mode=illumination",
      "GORYOKAKU event=touch action=confirm mode=tambourine"
    )
  end

  it "ignores confirmation without a candidate and touches outside Y-up and Z-up" do
    allow(detector).to receive(:detect).and_return(
      [%i[orientation_changed z_up], [:touch_pressed]],
      [%i[orientation_changed x_up], [:touch_pressed]]
    )

    runner.tick(0)
    runner.tick(1)

    expect(events.flatten).not_to include(:mode_changed, :mode_selected)
    expect(logger.messages).to include(
      "GORYOKAKU event=touch action=ignored reason=no_selection",
      "GORYOKAKU event=touch action=ignored orientation=x_up"
    )
  end

  it "publishes every motion sample and emits a periodic alive log" do
    runner.tick(4_999)
    runner.tick(5_000)

    expect(events.last).to eq([:motion_sample, 5_000, sample[:acceleration], sample[:gyroscope]])
    expect(logger.messages).to eq(["GORYOKAKU mode=combined event=alive"])
  end
end
