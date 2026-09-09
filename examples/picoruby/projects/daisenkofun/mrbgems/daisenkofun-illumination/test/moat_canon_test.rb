# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunMoatCanonCueSource
  attr_reader :latest_cues

  def initialize
    @latest_cues = [
      { moat: :inner, due_ms: 1_000, end_ms: 1_300, duty_percent: 3.4 },
      { moat: :middle, due_ms: 1_300, end_ms: 1_600, duty_percent: 3.0 },
      { moat: :outer, due_ms: 1_600, end_ms: 1_900, duty_percent: 2.6 }
    ]
  end
end

class DaisenkofunMoatCanonTest < Picotest::Test
  def setup
    @strip = WS2812.new(
      pin: Daisenkofun::Illumination::Config::LED_PIN,
      num: Daisenkofun::Illumination::LedLayout::LED_COUNT,
      order: Daisenkofun::Illumination::Config::LED_ORDER
    )
    @display = Daisenkofun::Illumination::Display.new(@strip)
    @pattern = Daisenkofun::Illumination::Biometrics::MoatCanon.new(cue_source: DaisenkofunMoatCanonCueSource.new)
    @pattern.beat({ timestamp_ms: 1_000 })
  end

  def pixel(outline)
    @strip.pixels[Daisenkofun::Illumination::LedLayout.outline_order(outline)[0]]
  end

  def test_follows_inner_middle_outer_cues
    @pattern.tick(@display, 1_000)
    assert pixel(2) > 0
    assert pixel(3) > 0
    assert_equal 0, pixel(4)

    @pattern.tick(@display, 1_300)
    assert_equal 0, pixel(2)
    assert pixel(3) > 0
    assert pixel(4) > 0

    @pattern.tick(@display, 1_600)
    assert_equal 0, pixel(2)
    assert_equal 0, pixel(3)
    assert pixel(4) > 0

    @pattern.tick(@display, 1_900)
    assert_equal 0, pixel(4)
    assert_false @pattern.pending?
  end

  def test_reset_clears_the_active_moat_on_the_next_tick
    @pattern.tick(@display, 1_000)
    assert pixel(2) > 0

    @pattern.reset
    @pattern.tick(@display, 1_010)
    assert_equal 0, pixel(2)
    assert_false @pattern.pending?
  end

  def test_does_not_resend_an_unchanged_frame
    @pattern.tick(@display, 1_000)
    frame_count = @strip.frame_count
    buffer_write_count = @strip.buffer_write_count

    @pattern.tick(@display, 1_050)

    assert_equal frame_count, @strip.frame_count
    assert_equal buffer_write_count, @strip.buffer_write_count
  end

  def test_updates_the_driver_buffer_once_between_moats
    @pattern.tick(@display, 1_000)
    first_writes = @strip.buffer_write_count

    @pattern.tick(@display, 1_300)

    assert_equal 1, first_writes
    assert_equal first_writes + 1, @strip.buffer_write_count
    assert_equal 0, @strip.set_rgb_count
  end
end
