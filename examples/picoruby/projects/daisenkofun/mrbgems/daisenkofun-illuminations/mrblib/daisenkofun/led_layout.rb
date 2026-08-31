# frozen_string_literal: true

# The single source of truth for the model's WS2812 physical addresses.
module Daisenkofun
  module LedLayout
    LED_COUNT = 572

    LEFT_LOWER = 0
    LEFT_UPPER = 1
    CIRCLE_SEGMENT = 2
    RIGHT_UPPER = 3
    RIGHT_LOWER = 4

    MOUND_TOP = 0
    MOUND_MIDDLE = 1
    MOUND_BASE = 2
    INNER_BANK = 3
    MIDDLE_BANK = 4

    # Each outline is defined once, from the left lower forepart clockwise to
    # the right lower forepart. Every other range and traversal is derived.
    SEGMENT_RANGES = [
      [[0, 1], [2, 17], [18, 33], [34, 49], [50, 51]],
      [[52, 57], [58, 74], [75, 108], [109, 125], [126, 131]],
      [[132, 140], [141, 159], [160, 201], [202, 220], [221, 229]],
      [[230, 248], [249, 282], [283, 333], [334, 367], [368, 385]],
      [[386, 407], [408, 446], [447, 509], [510, 547], [548, 569]]
    ]
    OUTLINE_COUNT = SEGMENT_RANGES.length
    MOUND_LAYER_COUNT = 3
    MOAT_BOUNDARIES = [[2, 3], [3, 4], [4]]

    CHAYAMA = 570
    DAIANJIYAMA = 571

    SCENE_ROW_COUNT = 21
    CHAYAMA_SCENE_POSITION = [1, -1]
    DAIANJIYAMA_SCENE_POSITION = [1, 1]

    def self.range_indices(range, reverse = false)
      indices = []
      index = reverse ? range[1] : range[0]
      while reverse ? index >= range[0] : index <= range[1]
        indices << index
        index += reverse ? -1 : 1
      end
      indices
    end

    def self.reverse_indices(indices)
      reversed = []
      index = indices.length - 1
      while index >= 0
        reversed << indices[index]
        index -= 1
      end
      reversed
    end

    def self.append_rows(rows, indices, first, last)
      index = 0
      while index < indices.length
        row = first + index * (last - first) / (indices.length - 1)
        rows[row] << indices[index]
        index += 1
      end
    end

    def self.append_outline_rows(rows, segments)
      circle = range_indices(segments[CIRCLE_SEGMENT])
      middle = circle.length / 2
      if circle.length % 2 == 0
        rows[0] << circle[middle - 1] << circle[middle]
        left_arc = circle[0...(middle - 1)]
        right_arc = circle[(middle + 1)..-1]
      else
        rows[0] << circle[middle]
        left_arc = circle[0...middle]
        right_arc = circle[(middle + 1)..-1]
      end
      append_rows(rows, reverse_indices(left_arc), 1, 5)
      append_rows(rows, right_arc, 1, 5)
      append_rows(rows, range_indices(segments[LEFT_UPPER], true), 6, 13)
      append_rows(rows, range_indices(segments[RIGHT_UPPER]), 6, 13)
      append_rows(rows, range_indices(segments[LEFT_LOWER], true), 14, 20)
      append_rows(rows, range_indices(segments[RIGHT_LOWER]), 14, 20)
    end

    def self.append_indices(target, source)
      index = 0
      while index < source.length
        target << source[index]
        index += 1
      end
      target
    end

    def self.build_outline_data
      data = [[], [], [], [], [], [], []]
      outline = 0
      while outline < OUTLINE_COUNT
        segments = SEGMENT_RANGES[outline]
        range = [segments[LEFT_LOWER][0], segments[RIGHT_LOWER][1]]
        left = range_indices(segments[LEFT_LOWER]) + range_indices(segments[LEFT_UPPER])
        right = range_indices(segments[RIGHT_LOWER], true) + range_indices(segments[RIGHT_UPPER], true)
        data[0] << range
        data[1] << range_indices(range)
        data[2] << left
        data[3] << right
        data[4] << range_indices(segments[CIRCLE_SEGMENT])
        data[5] << reverse_indices(left)
        data[6] << reverse_indices(right)
        outline += 1
      end
      data
    end

    def self.build_outline_sequence(orders, reverse = false)
      result = []
      outline = reverse ? orders.length - 1 : 0
      while reverse ? outline >= 0 : outline < orders.length
        append_indices(result, orders[outline])
        outline += reverse ? -1 : 1
      end
      result
    end

    def self.build_symmetric_forepart_pairs(left_order, right_order)
      pairs = []
      index = left_order.length - 1
      while index >= 0
        pairs << [left_order[index], right_order[index]]
        index -= 1
      end
      pairs
    end

    def self.build_scene_rows
      rows = []
      row = 0
      while row < SCENE_ROW_COUNT
        rows << []
        row += 1
      end
      outline = 0
      while outline < OUTLINE_COUNT
        append_outline_rows(rows, SEGMENT_RANGES[outline])
        outline += 1
      end
      rows
    end

    def self.flatten_rows(rows)
      order = []
      row = 0
      while row < rows.length
        append_indices(order, rows[row])
        row += 1
      end
      order
    end

    OUTLINE_DATA = build_outline_data
    OUTLINE_RANGES = OUTLINE_DATA[0]
    OUTLINE_ORDERS = OUTLINE_DATA[1]
    LEFT_ORDERS = OUTLINE_DATA[2]
    RIGHT_ORDERS = OUTLINE_DATA[3]
    CIRCLE_ORDERS = OUTLINE_DATA[4]
    LEFT_CIRCLE_TO_FOREPART_ORDERS = OUTLINE_DATA[5]
    RIGHT_CIRCLE_TO_FOREPART_ORDERS = OUTLINE_DATA[6]
    MAIN_ORDER = build_outline_sequence(OUTLINE_ORDERS)
    OUTSIDE_TO_INSIDE_ORDER = build_outline_sequence(OUTLINE_ORDERS, true)
    SYMMETRIC_FOREPART_PAIRS = build_symmetric_forepart_pairs(LEFT_ORDERS[MOUND_BASE], RIGHT_ORDERS[MOUND_BASE])
    SCENE_ROWS = build_scene_rows
    NORTH_TO_SOUTH_ORDER = flatten_rows(SCENE_ROWS)
    SOUTH_TO_NORTH_ORDER = reverse_indices(NORTH_TO_SOUTH_ORDER)

    def self.outline_range(index)
      OUTLINE_RANGES[index]
    end

    def self.outline_order(index)
      OUTLINE_ORDERS[index]
    end

    def self.clockwise_order(index)
      OUTLINE_ORDERS[index]
    end

    def self.main_order
      MAIN_ORDER
    end

    def self.segment_order(outline, segment, reverse = false)
      range_indices(SEGMENT_RANGES[outline][segment], reverse)
    end

    def self.left_order(outline)
      LEFT_ORDERS[outline]
    end

    def self.right_order(outline)
      RIGHT_ORDERS[outline]
    end

    def self.circle_order(outline)
      CIRCLE_ORDERS[outline]
    end

    def self.symmetric_forepart_pairs
      SYMMETRIC_FOREPART_PAIRS
    end

    def self.inside_to_outside_order
      MAIN_ORDER
    end

    def self.outside_to_inside_order
      OUTSIDE_TO_INSIDE_ORDER
    end

    def self.forepart_to_circle_order(outline, side)
      return LEFT_ORDERS[outline] if side == :left
      return RIGHT_ORDERS[outline] if side == :right

      raise ArgumentError, "side must be :left or :right"
    end

    def self.circle_to_forepart_order(outline, side)
      return LEFT_CIRCLE_TO_FOREPART_ORDERS[outline] if side == :left
      return RIGHT_CIRCLE_TO_FOREPART_ORDERS[outline] if side == :right

      raise ArgumentError, "side must be :left or :right"
    end

    def self.scene_rows
      SCENE_ROWS
    end

    def self.north_to_south_order
      NORTH_TO_SOUTH_ORDER
    end

    def self.south_to_north_order
      SOUTH_TO_NORTH_ORDER
    end

    def self.attached_scene_position(index)
      return CHAYAMA_SCENE_POSITION if index == CHAYAMA
      return DAIANJIYAMA_SCENE_POSITION if index == DAIANJIYAMA

      raise ArgumentError, "unknown attached kofun"
    end
  end
end
