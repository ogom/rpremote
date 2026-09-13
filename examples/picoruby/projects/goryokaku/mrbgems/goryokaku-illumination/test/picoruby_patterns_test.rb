# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuIlluminationPicorubyPatternsTest < Picotest::Test
  PICORUBY_KEYS = [
    :kouhaku, :twinkle, :shooting_star, :breathing, :constellation,
    :sakura_fubuki, :sakura_stream, :sakura_gradient,
    :sakura_breathing, :hanami, :mankai
  ]

  def test_registers_each_migrated_pattern
    PICORUBY_KEYS.each do |key|
      assert Goryokaku::Illumination::Setlist.pattern_class(key)
    end
  end

  def test_kouhaku_uses_the_shared_380_led_display
    strip = WS2812.new(pin: Goryokaku::Illumination::Config::LED_PIN, num: Goryokaku::Illumination::LedLayout::LED_COUNT)
    display = Goryokaku::Illumination::Display.new(strip)

    Goryokaku::Illumination::Patterns::Kouhaku.new(display, 0, 1).call

    assert_equal 0x7F7F7F, strip.pixels[0]
    assert_equal 0x7F0000, strip.pixels[1]
    assert_equal Goryokaku::Illumination::LedLayout::LED_COUNT, strip.pixels.length
  end
end
