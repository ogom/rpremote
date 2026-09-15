# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunCanonTestClock
  attr_accessor :now

  def initialize
    @now = 0
  end

  def millis
    @now
  end
end

class DaisenkofunCanonTestPWM
  attr_reader :notes, :last_duty

  def initialize(clock)
    @clock = clock
    @notes = []
  end

  def frequency(value)
    @frequency = value
  end

  def duty(value)
    @last_duty = value
    @notes << [@clock.millis, @frequency, value] if value > 0
  end
end

class DaisenkofunMusicalKofunCanonOutputTest < Picotest::Test
  def test_plays_three_nonblocking_cues_and_cancels_old_cues_on_a_new_beat
    clock = DaisenkofunCanonTestClock.new
    pwm = DaisenkofunCanonTestPWM.new(clock)
    output = Daisenkofun::Musical::Outputs::KofunCanon.new(clock: clock, pwm: pwm)
    subscriber = Daisenkofun::Musical::Subscriber.new(output: output, immediate_beat: true)
    subscriber.start

    clock.now = 1_000
    subscriber.call(:beat, { timestamp_ms: 1_000, interval_ms: 900 })
    clock.now = 1_300
    subscriber.tick(1_300)
    clock.now = 1_450
    subscriber.call(:beat, { timestamp_ms: 1_450, interval_ms: 900 })
    clock.now = 1_750
    subscriber.tick(1_750)

    assert_equal [[1_000, 294, 3.4], [1_300, 392, 3.0], [1_450, 392, 3.0], [1_750, 523, 2.6]], pwm.notes
    assert_equal 4, output.cue_count
    assert_equal 0, output.max_delay_ms
  ensure
    subscriber.stop if subscriber
  end

  def test_fixed_replay_has_the_probe_canon_sequence_and_summary
    clock = DaisenkofunCanonTestClock.new
    pwm = DaisenkofunCanonTestPWM.new(clock)
    output = Daisenkofun::Musical::Outputs::KofunCanon.new(clock: clock, pwm: pwm)
    subscriber = Daisenkofun::Musical::Subscriber.new(output: output, immediate_beat: true)
    subscriber.start
    beats = [[0, 900], [900, 800], [1_700, 760], [2_460, 840], [3_300, 800]]
    beats.each do |at, interval|
      clock.now = at
      subscriber.call(:beat, {
        timestamp_ms: at,
        interval_ms: interval,
        pulse_width_ratio: 0.25,
        pulse_width_ms: interval / 4,
        pulse_amplitude: 1_000,
        pulse_samples: 20
      })
      clock.now = at + interval / 3
      subscriber.tick(clock.now)
      clock.now = at + interval * 2 / 3
      subscriber.tick(clock.now)
    end

    assert_equal [
      [294, 3.4], [392, 3.0], [523, 2.6],
      [440, 3.0], [587, 2.6], [330, 3.4],
      [587, 2.6], [330, 3.4], [440, 3.0],
      [392, 3.0], [523, 2.6], [294, 3.4],
      [587, 2.6], [330, 3.4], [440, 3.0]
    ], pwm.notes.map { |note| [note[1], note[2]] }
    assert_equal({ status: :ok, cues: 15, max_delay_ms: 0 }, output.verification)
  ensure
    subscriber.stop if subscriber
  end
end
