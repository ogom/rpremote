# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunColorTest < Picotest::Test
  def test_extracts_and_combines_rgb_components
    color = 0x123456

    assert_equal 0x12, Daisenkofun::Color.red(color)
    assert_equal 0x34, Daisenkofun::Color.green(color)
    assert_equal 0x56, Daisenkofun::Color.blue(color)
    assert_equal color, Daisenkofun::Color.rgb(0x12, 0x34, 0x56)
  end

  def test_scale_clamps_negative_levels_and_power_limits
    assert_equal 0x000000, Daisenkofun::Color.scale(0xffffff, -1.0)
    assert_equal 0x787878, Daisenkofun::Color.scale(0xffffff, 1.0)
  end

  def test_blend_clamps_amount
    assert_equal 0xff0000, Daisenkofun::Color.blend(0xff0000, 0x0000ff, -1.0)
    assert_equal 0x0000ff, Daisenkofun::Color.blend(0xff0000, 0x0000ff, 2.0)
    assert_equal 0x7f007f, Daisenkofun::Color.blend(0xff0000, 0x0000ff, 0.5)
  end

  def test_rainbow_wraps_positions
    assert_equal Daisenkofun::Color::RAINBOW[0], Daisenkofun::Color.rainbow(0)
    assert_equal Daisenkofun::Color::RAINBOW[0], Daisenkofun::Color.rainbow(Daisenkofun::Color::RAINBOW.length)
  end
end
