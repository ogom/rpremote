# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunIlluminationBiometricPlayerTestLogger
  attr_reader :messages

  def initialize
    @messages = []
  end

  def puts(message)
    @messages << message
  end
end

class DaisenkofunIlluminationBiometricPlayerResettablePattern
  attr_reader :reset_count

  def initialize
    @reset_count = 0
  end

  def beat(_payload)
  end

  def tick(_display, _now)
  end

  def reset
    @reset_count += 1
  end
end

class DaisenkofunIlluminationBiometricPlayerTest < Picotest::Test
  def test_event_only_schedules_work_and_tick_renders_at_most_one_frame
    strip = WS2812.new(
      pin: Daisenkofun::Illumination::Config::LED_PIN,
      num: Daisenkofun::Illumination::LedLayout::LED_COUNT,
      order: Daisenkofun::Illumination::Config::LED_ORDER
    )
    illumination = Daisenkofun::Illumination::BiometricPlayer.new(strip: strip, logger: DaisenkofunIlluminationBiometricPlayerTestLogger.new)
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
      pin: Daisenkofun::Illumination::Config::LED_PIN,
      num: Daisenkofun::Illumination::LedLayout::LED_COUNT,
      order: Daisenkofun::Illumination::Config::LED_ORDER
    )
    logger = DaisenkofunIlluminationBiometricPlayerTestLogger.new
    illumination = Daisenkofun::Illumination::BiometricPlayer.new(strip: strip, logger: logger)

    illumination.start
    illumination.stop
    assert strip.closed
    assert_equal 0, strip.pixels[0]
    assert logger.messages.include?("DAISENKOFUN mode=combined component=illumination event=stop")
  end

  def test_finger_removal_resets_a_resettable_pattern
    pattern = DaisenkofunIlluminationBiometricPlayerResettablePattern.new
    illumination = Daisenkofun::Illumination::BiometricPlayer.new(
      strip: WS2812.new(
        pin: Daisenkofun::Illumination::Config::LED_PIN,
        num: Daisenkofun::Illumination::LedLayout::LED_COUNT,
        order: Daisenkofun::Illumination::Config::LED_ORDER
      ),
      pattern: pattern,
      logger: DaisenkofunIlluminationBiometricPlayerTestLogger.new
    )
    illumination.start
    illumination.call(:finger_removed, {})
    assert_equal 1, pattern.reset_count
  ensure
    illumination.stop if illumination
  end
end
