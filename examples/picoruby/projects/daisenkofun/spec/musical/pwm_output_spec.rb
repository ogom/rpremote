# frozen_string_literal: true

require_relative "../spec_helper"

RSpec.describe Daisenkofun::Musical::Outputs::PWM do
  it "maps pulse width to 2–6 percent duty before applying master volume" do
    translator = Daisenkofun::Musical::Translators::Timbre.new

    expect(translator.translate(pulse_width_ratio: 0.0)[:duty_percent]).to eq(2.0)
    expect(translator.translate(pulse_width_ratio: 0.5)[:duty_percent]).to eq(4.0)
    expect(translator.translate(pulse_width_ratio: 1.0)[:duty_percent]).to eq(6.0)
    expect(translator.translate({})[:duty_percent]).to eq(3.0)
  end

  it "scales volume and caps the audible square wave at 50 percent duty" do
    clock = DaisenkofunSpec::Clock.new(1_000)
    pwm = DaisenkofunSpec::PWM.new(clock)
    output = described_class.new(clock: clock, pwm: pwm, volume: 100).start

    output.beat(timestamp_ms: 1_000, interval_ms: 900, pulse_width_ratio: 1.0)
    output.tick(1_000)

    expect(pwm.notes).to eq([[1_000, 294, 50.0]])
  ensure
    output&.stop
  end

  it "does not turn a buffered beat older than 100 ms into a fresh note" do
    clock = DaisenkofunSpec::Clock.new(1_000)
    pwm = DaisenkofunSpec::PWM.new(clock)
    output = described_class.new(clock: clock, pwm: pwm).start
    output.beat(timestamp_ms: 1_000, interval_ms: 900)
    clock.now = 1_101

    output.tick(clock.now)

    expect(pwm.notes).to be_empty
  ensure
    output&.stop
  end
end
