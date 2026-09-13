# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuIlluminationDisplayTest < Picotest::Test
  def setup
    @strip = WS2812.new(pin: 22, num: Goryokaku::Illumination::LedLayout::LED_COUNT)
    @display = Goryokaku::Illumination::Display.new(@strip)
  end

  def test_preserves_physical_zone_boundaries
    layout = Goryokaku::Illumination::LedLayout
    assert_equal [0, 169], layout::ZONE_RANGES[layout::STAR]
    assert_equal [170, 189], layout::ZONE_RANGES[layout::RAVELIN]
    assert_equal [190, 379], layout::ZONE_RANGES[layout::OUTER]
    assert_equal 170, layout::STAR_SEGMENT_RANGES.sum { |range| range[1] - range[0] + 1 }
  end

  def test_writes_only_selected_zone
    layout = Goryokaku::Illumination::LedLayout
    @display.fill_zone(layout::RAVELIN, Goryokaku::Illumination::Color::RAVELIN, 1.0)
    @display.show

    assert_equal 0x000000, @strip.pixels[169]
    assert_equal 0x00C8FF, @strip.pixels[170]
    assert_equal 0x00C8FF, @strip.pixels[189]
    assert_equal 0x000000, @strip.pixels[190]
  end

  def test_clear_turns_every_led_off
    @display.fill_zone(Goryokaku::Illumination::LedLayout::OUTER, Goryokaku::Illumination::Color::OUTER)
    @display.clear

    assert_equal 380, @strip.pixels.count { |pixel| pixel == 0 }
  end

  def test_uses_bulk_buffer_writes
    @display.fill_zone(Goryokaku::Illumination::LedLayout::STAR, Goryokaku::Illumination::Color::WARM_WHITE)
    @display.show

    assert_equal 1, @strip.buffer_write_count
    assert_equal 0, @strip.set_rgb_count
  end
end
