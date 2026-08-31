# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunLedLayoutTest < Picotest::Test
  def test_sections_cover_every_led_once
    ranges = Daisenkofun::LedLayout::SEGMENT_RANGES.flatten(1)
    ranges += [[Daisenkofun::LedLayout::CHAYAMA, Daisenkofun::LedLayout::CHAYAMA]]
    ranges += [[Daisenkofun::LedLayout::DAIANJIYAMA, Daisenkofun::LedLayout::DAIANJIYAMA]]
    indices = expand_ranges(ranges)

    assert_equal (0...Daisenkofun::LedLayout::LED_COUNT).to_a, indices.sort
    assert_equal indices.length, indices.uniq.length
  end

  def test_outline_segments_cover_each_outline_once
    Daisenkofun::LedLayout::SEGMENT_RANGES.each_with_index do |segments, outline|
      expected = expand_ranges([Daisenkofun::LedLayout.outline_range(outline)])
      actual = expand_ranges(segments)
      assert_equal expected, actual
      assert_equal actual.length, actual.uniq.length
    end
  end

  def test_main_and_scene_orders_cover_main_leds_once
    expected = (0...Daisenkofun::LedLayout::CHAYAMA).to_a
    main_order = Daisenkofun::LedLayout.main_order
    scene_order = Daisenkofun::LedLayout.scene_rows.flatten

    assert_equal expected, main_order.sort
    assert_equal main_order.length, main_order.uniq.length
    assert_equal expected, scene_order.sort
    assert_equal scene_order.length, scene_order.uniq.length
  end

  def test_generated_orders_are_reused
    assert_equal Daisenkofun::LedLayout::MAIN_ORDER.object_id,
                 Daisenkofun::LedLayout.main_order.object_id
    assert_equal Daisenkofun::LedLayout::SCENE_ROWS.object_id,
                 Daisenkofun::LedLayout.scene_rows.object_id
    assert_equal false, Daisenkofun.const_defined?(:Layout)
  end

  def test_all_public_orders_stay_inside_led_range
    orders = [
      Daisenkofun::LedLayout.inside_to_outside_order,
      Daisenkofun::LedLayout.outside_to_inside_order,
      Daisenkofun::LedLayout.north_to_south_order,
      Daisenkofun::LedLayout.south_to_north_order
    ]
    outline = 0
    while outline < Daisenkofun::LedLayout::OUTLINE_COUNT
      orders << Daisenkofun::LedLayout.outline_order(outline)
      orders << Daisenkofun::LedLayout.left_order(outline)
      orders << Daisenkofun::LedLayout.right_order(outline)
      orders << Daisenkofun::LedLayout.circle_order(outline)
      orders << Daisenkofun::LedLayout.forepart_to_circle_order(outline, :left)
      orders << Daisenkofun::LedLayout.forepart_to_circle_order(outline, :right)
      orders << Daisenkofun::LedLayout.circle_to_forepart_order(outline, :left)
      orders << Daisenkofun::LedLayout.circle_to_forepart_order(outline, :right)
      outline += 1
    end
    orders << Daisenkofun::LedLayout.symmetric_forepart_pairs.flatten

    invalid = orders.flatten.select do |index|
      index < 0 || index >= Daisenkofun::LedLayout::LED_COUNT
    end
    assert_equal [], invalid
  end

  private

  def expand_ranges(ranges)
    indices = []
    ranges.each do |range|
      index = range[0]
      while index <= range[1]
        indices << index
        index += 1
      end
    end
    indices
  end
end
