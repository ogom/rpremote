# frozen_string_literal: true

require_relative "test_helper"

class GoryokakuIlluminationTambourinePlayerTest < Picotest::Test
  def build_player
    strip = WS2812.new(pin: 14, num: Goryokaku::Illumination::LedLayout::LED_COUNT)
    device = Goryokaku::Illumination::Device.new(strip: strip)
    [Goryokaku::Illumination::TambourinePlayer.new(device: device), strip]
  end

  def test_shake_starts_at_group_five_and_follows_direction
    player, strip = build_player
    player.start
    player.on_event([:tambourine_shaken, 0, 1.0, :right, 100])
    player.tick(0)
    group_five = Goryokaku::Illumination::LedLayout.star_group(4)
    assert group_five.all? { |index| strip.pixels[index] != 0 }
    assert_equal 0, strip.pixels[0]

    player.tick(20)
    assert Goryokaku::Illumination::LedLayout.star_group(0).all? { |index| strip.pixels[index] != 0 }
  end

  def test_strike_bursts_from_the_star_to_the_outer_ring
    player, strip = build_player
    player.start
    player.on_event([:tambourine_struck, 0, 1.0, 120])
    player.tick(0)

    assert strip.pixels[0] != 0
    assert strip.pixels[170] != 0
    assert strip.pixels[190..379].any? { |pixel| pixel != 0 }

    player.tick(60)
    assert strip.pixels[190..379].all? { |pixel| pixel != 0 }
    assert strip.pixels[0..169].uniq.length > 2
    player.tick(120)
    assert strip.pixels.all? { |pixel| pixel == 0 }
  end

  def test_inactive_and_stop_clear_the_strip
    player, strip = build_player
    player.start
    player.on_event([:tambourine_struck, 0, 1.0, 120])
    player.tick(0)
    player.on_event([:tambourine_inactive])
    assert strip.pixels.all? { |pixel| pixel == 0 }
    player.stop
    assert strip.closed
  end
end
