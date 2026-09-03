# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunMusicalFakeOutput
  attr_reader :beats, :ticks, :start_count, :stop_count

  def initialize
    @beats = []
    @ticks = []
    @start_count = 0
    @stop_count = 0
  end

  def start
    @start_count += 1
  end

  def beat(payload)
    @beats << payload
  end

  def tick(now)
    @ticks << now
  end

  def stop
    @stop_count += 1
  end
end

class DaisenkofunMusicalBeatSubscriberTest < Picotest::Test
  def test_beat_is_deferred_until_tick
    output = DaisenkofunMusicalFakeOutput.new
    subscriber = Daisenkofun::Musical::BeatSubscriber.new(output: output)
    payload = { timestamp_ms: 1_000, bpm: 72.0 }

    subscriber.start
    subscriber.call(:beat, payload)
    assert_equal [], output.beats

    subscriber.tick(1_002)
    assert_equal [payload], output.beats
    assert_equal [1_002], output.ticks
  ensure
    subscriber.stop if subscriber
  end

  def test_non_beat_events_do_not_trigger_output
    output = DaisenkofunMusicalFakeOutput.new
    subscriber = Daisenkofun::Musical::BeatSubscriber.new(output: output)

    subscriber.start
    subscriber.call(:measurement_updated, { bpm: 72.0 })
    subscriber.tick(10)

    assert_equal [], output.beats
    assert_equal 1, output.start_count
    subscriber.stop
    assert_equal 1, output.stop_count
  end
end
