# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunBeatIlluminationTestLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunBeatIlluminationTest < Picotest::Test
  def test_event_only_schedules_work_and_tick_renders_at_most_one_frame
    strip = WS2812.new(
      pin: Daisenkofun::Config::LED_PIN,
      num: Daisenkofun::LedLayout::LED_COUNT,
      order: Daisenkofun::Config::LED_ORDER
    )
    illumination = Daisenkofun::BeatIllumination.new(
      strip: strip,
      logger: DaisenkofunBeatIlluminationTestLogger.new
    )
    illumination.start
    initial_frames = strip.frame_count

    illumination.call(:beat, { timestamp_ms: 1_000, bpm: 72.0 })
    assert_equal initial_frames, strip.frame_count

    illumination.tick(1_000)
    assert_equal initial_frames + 1, strip.frame_count
    illumination.tick(1_010)
    assert_equal initial_frames + 1, strip.frame_count
    illumination.tick(1_050)
    assert_equal initial_frames + 2, strip.frame_count
  ensure
    illumination.stop if illumination
  end

  def test_stop_turns_off_and_releases_the_strip
    strip = WS2812.new(
      pin: Daisenkofun::Config::LED_PIN,
      num: Daisenkofun::LedLayout::LED_COUNT,
      order: Daisenkofun::Config::LED_ORDER
    )
    logger = DaisenkofunBeatIlluminationTestLogger.new
    illumination = Daisenkofun::BeatIllumination.new(strip: strip, logger: logger)

    illumination.start
    illumination.stop
    assert strip.closed
    assert_equal 0, strip.pixels[0]
    assert logger.messages.include?(
      "DAISENKOFUN mode=combined component=beat_illumination event=stop"
    )
  end
end
