# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Goryokaku::Musical::IlluminationSoundtrack do
  it "plays Twinkle Twinkle Little Star once with the documented duration" do
    output = GoryokakuSpec::Output.new
    waiter = GoryokakuSpec::Clock.new
    soundtrack = described_class.new(output: output, volume: 0.5, waiter: waiter)

    soundtrack.start.join

    plays = output.events.select { |event| event.first == :play }
    expect(plays.map { |event| event[1] }).to eq([262, 262, 392, 392, 440, 440, 392, 349, 349, 330, 330, 294, 294, 262])
    expect(plays.map { |event| event[2] }.uniq).to eq([0.5])
    expect(waiter.waits.sum).to eq(7_100)
    expect(output.events.last).to eq([:stop])
  end

  it "starts the melody again after the final gap when repeating" do
    output = GoryokakuSpec::Output.new
    soundtrack = described_class.new(output: output, waiter: GoryokakuSpec::Clock.new)

    soundtrack.start(repeat: true).wait_ms(7_100)

    expect(output.events.count { |event| event.first == :play }).to eq(15)
    expect(output.events.last).to eq([:play, 262, 1])
  ensure
    soundtrack&.stop
  end

  it "always silences the output when stopped" do
    output = GoryokakuSpec::Output.new
    soundtrack = described_class.new(output: output, waiter: GoryokakuSpec::Clock.new).start

    soundtrack.stop

    expect(output.events.last).to eq([:stop])
  end
end
