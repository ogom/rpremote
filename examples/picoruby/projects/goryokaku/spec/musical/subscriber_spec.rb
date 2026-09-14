# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Musical::Subscriber do
  it "plays motion only in tambourine mode and silences queued sound when illumination returns" do
    output = GoryokakuSpec::Output.new
    subscriber = described_class.new(output: output, mode: :illumination)

    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    subscriber.tick(0)
    subscriber.on_event(%i[mode_changed tambourine])
    subscriber.on_event([:tambourine_shaken, 100, 1.0, :right, 100])
    subscriber.tick(100)
    subscriber.on_event(%i[mode_changed illumination])

    expect(output.events).to eq([[:play, 4_200, 1.0], [:stop]])
  end

  it "plays complete decaying shake and strike sequences" do
    output = GoryokakuSpec::Output.new
    subscriber = described_class.new(output: output, mode: :tambourine)
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    [0, 20, 40, 60, 80, 100].each { |now| subscriber.tick(now) }
    subscriber.on_event([:tambourine_struck, 100, 1.0, 120])
    [100, 120, 140, 160, 180, 200, 220].each { |now| subscriber.tick(now) }

    plays = output.events.select { |event| event.first == :play }
    expect(plays.map { |event| event[1] }).to eq([4_200, 6_500, 5_200, 7_400, 4_600, 5_200, 7_800, 4_600, 6_900, 4_100, 5_800])
  end

  it "combines master volume, gesture intensity, and cue decay without growing an active queue" do
    output = GoryokakuSpec::Output.new
    subscriber = described_class.new(output: output, volume: 0.8, mode: :tambourine)
    subscriber.on_event([:tambourine_struck, 0, 0.5, 120])
    subscriber.tick(0)
    subscriber.on_event([:tambourine_shaken, 20, 1.0, :left, 100])
    subscriber.tick(120)

    expect(output.events.first[0, 2]).to eq([:play, 5_200])
    expect(output.events.first[2]).to be_within(0.0001).of(0.6)
    expect(output.events.count { |event| event.first == :play }).to eq(1)
  end
end
