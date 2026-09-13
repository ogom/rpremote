# frozen_string_literal: true

require_relative "test_helper"

class FakeIlluminationSoundtrackOutput
  attr_reader :events

  def initialize; @events = []; end
  def start; @events << [:start]; end
  def play(frequency, volume); @events << [:play, frequency, volume]; end
  def stop; @events << [:stop]; end
end

class FakeIlluminationSoundtrackWaiter
  attr_reader :waits

  def initialize; @waits = []; end
  def wait_ms(milliseconds); @waits << milliseconds; end
end

class GoryokakuMusicalIlluminationSoundtrackTest < Picotest::Test
  def test_plays_twinkle_twinkle_little_star_once
    output = FakeIlluminationSoundtrackOutput.new
    waiter = FakeIlluminationSoundtrackWaiter.new
    soundtrack = Goryokaku::Musical::IlluminationSoundtrack.new(
      output: output, volume: 0.5, waiter: waiter
    )

    soundtrack.start.join

    plays = output.events.select { |event| event[0] == :play }
    assert_equal [262, 262, 392, 392, 440, 440, 392, 349, 349, 330, 330, 294, 294, 262], plays.map { |event| event[1] }
    assert plays.all? { |event| event[2] == 0.5 }
    assert_equal 14, Goryokaku::Musical::IlluminationSoundtrack::MELODY.length
    assert_equal 800, Goryokaku::Musical::IlluminationSoundtrack::MELODY[6][1]
    assert_equal 800, Goryokaku::Musical::IlluminationSoundtrack::MELODY[13][1]
    assert_equal 7_100, waiter.waits.inject(0) { |total, duration| total + duration }
    assert_equal :stop, output.events[-1][0]
  end

  def test_repeats_after_the_last_gap
    output = FakeIlluminationSoundtrackOutput.new
    waiter = FakeIlluminationSoundtrackWaiter.new
    soundtrack = Goryokaku::Musical::IlluminationSoundtrack.new(output: output, waiter: waiter)

    soundtrack.start(repeat: true)
    soundtrack.wait_ms(7_100)
    soundtrack.stop

    plays = output.events.select { |event| event[0] == :play }
    assert_equal 15, plays.length
    assert_equal 262, plays[-1][1]
  end

  def test_stop_silences_the_output
    output = FakeIlluminationSoundtrackOutput.new
    soundtrack = Goryokaku::Musical::IlluminationSoundtrack.new(
      output: output, waiter: FakeIlluminationSoundtrackWaiter.new
    )

    soundtrack.start
    soundtrack.stop

    assert_equal :stop, output.events[-1][0]
  end
end
