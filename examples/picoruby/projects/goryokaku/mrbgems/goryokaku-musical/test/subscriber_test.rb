# frozen_string_literal: true

require_relative "test_helper"

class FakeMusicalOutput
  attr_reader :events
  def initialize; @events = []; end
  def start; @events << [:start]; end
  def play(frequency, volume); @events << [:play, frequency, volume]; end
  def stop; @events << [:stop]; end
end

class GoryokakuMusicalSubscriberTest < Picotest::Test
  def test_plays_motion_only_in_tambourine_mode
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, volume: 0.5)
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    subscriber.tick(0)
    subscriber.on_event([:mode_changed, :tambourine])
    subscriber.on_event([:tambourine_shaken, 100, 1.0, :right, 100])
    subscriber.tick(100)
    subscriber.tick(200)
    assert_equal [[:play, 4_200, 0.5], [:stop]], output.events
  end

  def test_returning_to_illumination_clears_queue_and_silences_output
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output)
    subscriber.on_event([:mode_changed, :tambourine])
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    subscriber.on_event([:mode_changed, :illumination])
    subscriber.tick(0)
    assert_equal [[:stop]], output.events
  end

  def test_musical_mode_starts_as_a_tambourine
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, mode: :tambourine)
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    subscriber.tick(0)
    assert_equal [[:play, 4_200, 1.0]], output.events
  end

  def test_uses_first_shake_and_strike_shimmer_cues
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, mode: :tambourine)

    subscriber.on_event([:tambourine_shaken, 0, 1.0, :left, 100])
    subscriber.tick(0)
    subscriber.tick(100)
    subscriber.on_event([:tambourine_struck, 100, 1.0, 120])
    subscriber.tick(100)
    subscriber.tick(220)

    assert_equal [[:play, 4_600, 1.0], [:stop], [:play, 5_200, 1.0], [:stop]], output.events
  end

  def test_does_not_grow_the_motion_queue_while_playing
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, mode: :tambourine)
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    subscriber.tick(0)
    subscriber.on_event([:tambourine_shaken, 20, 1.0, :left, 100])
    subscriber.tick(100)
    subscriber.tick(120)

    assert_equal [[:play, 4_200, 1.0], [:stop]], output.events
  end

  def test_scales_volume_from_the_shared_intensity
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, volume: 0.8, mode: :tambourine)
    subscriber.on_event([:tambourine_struck, 0, 0.5, 120])
    subscriber.tick(0)

    assert_in_delta 0.6, output.events[0][2]
  end

  def test_plays_a_decaying_shan_shan_sequence
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, mode: :tambourine)
    subscriber.on_event([:tambourine_shaken, 0, 1.0, :right, 100])

    subscriber.tick(0)
    subscriber.tick(20)
    subscriber.tick(40)
    subscriber.tick(60)
    subscriber.tick(80)
    subscriber.tick(100)

    assert_equal [4_200, 6_500, 5_200, 7_400, 4_600], output.events.select { |event| event[0] == :play }.map { |event| event[1] }
    levels = output.events.select { |event| event[0] == :play }.map { |event| event[2] }
    assert_equal [1.0, 0.82, 0.66, 0.48, 0.30], levels
    assert_equal :stop, output.events[-1][0]
  end

  def test_plays_a_sharp_decaying_shan_shan_sequence_for_a_strike
    output = FakeMusicalOutput.new
    subscriber = Goryokaku::Musical::Subscriber.new(output: output, mode: :tambourine)
    subscriber.on_event([:tambourine_struck, 0, 1.0, 120])

    subscriber.tick(0)
    subscriber.tick(20)
    subscriber.tick(40)
    subscriber.tick(60)
    subscriber.tick(80)
    subscriber.tick(100)
    subscriber.tick(120)

    plays = output.events.select { |event| event[0] == :play }
    assert_equal [5_200, 7_800, 4_600, 6_900, 4_100, 5_800], plays.map { |event| event[1] }
    assert_equal [1.0, 0.90, 0.76, 0.60, 0.44, 0.28], plays.map { |event| event[2] }
    assert_equal :stop, output.events[-1][0]
  end
end
