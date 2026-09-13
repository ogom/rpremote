# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunPWMTestClock
  attr_accessor :now

  def initialize; @now = 0; end
  def millis; @now; end
end

class DaisenkofunPWMTestDevice
  attr_reader :notes

  def initialize(clock)
    @clock = clock
    @notes = []
  end

  def frequency(value); @frequency = value; end

  def duty(value)
    @notes << [@clock.millis, @frequency, value] if value > 0
  end
end

class DaisenkofunMusicalPWMOutputTest < Picotest::Test
  def test_scales_pulse_duty_with_master_volume
    clock = DaisenkofunPWMTestClock.new
    pwm = DaisenkofunPWMTestDevice.new(clock)
    output = Daisenkofun::Musical::Outputs::PWM.new(clock: clock, pwm: pwm, volume: 1.5)
    subscriber = Daisenkofun::Musical::Subscriber.new(output: output, immediate_beat: true)
    subscriber.start

    clock.now = 1_000
    subscriber.call(:beat, {
      timestamp_ms: 1_000, interval_ms: 900, pulse_width_ratio: 0.5,
      pulse_width_ms: 450, pulse_amplitude: 1_000, pulse_samples: 20
    })

    assert_equal [[1_000, 294, 2.0]], pwm.notes
  ensure
    subscriber.stop if subscriber
  end
end
