# frozen_string_literal: true

# The single source of truth for the model's WS2812 physical addresses.
module Goryokaku
  module Illumination
    module LedLayout
      LED_COUNT = 380
      STAR = 0
      RAVELIN = 1
      OUTER = 2
      ZONE_RANGES = [[0, 169], [170, 189], [190, 379]]
      STAR_SEGMENT_RANGES = [
        [0, 16], [17, 33], [34, 50], [51, 67], [68, 84],
        [85, 101], [102, 118], [119, 134], [135, 151], [152, 169]
      ]
      PARALLEL_LEFT = [4, 5, 6, 7, 8]
      PARALLEL_RIGHT = [9, 0, 1, 2, 3]
      MUSICAL_GROUP_ORDER = [4, 0, 1, 2, 3]

      def self.range_indices(range, reverse = false)
        result = []
        index = reverse ? range[1] : range[0]
        while reverse ? index >= range[0] : index <= range[1]
          result << index
          index += reverse ? -1 : 1
        end
        result
      end

      def self.zone_order(zone)
        range_indices(ZONE_RANGES[zone])
      end

      def self.star_order
        zone_order(STAR)
      end

      def self.all_order
        range_indices([0, LED_COUNT - 1])
      end

      def self.ravelin_order
        zone_order(RAVELIN)
      end

      def self.outer_order(start_offset = 0)
        order = []
        count = ZONE_RANGES[OUTER][1] - ZONE_RANGES[OUTER][0] + 1
        index = 0
        while index < count
          order << ZONE_RANGES[OUTER][0] + (start_offset + index) % count
          index += 1
        end
        order
      end

      def self.star_segment(index, radial = false)
        range_indices(STAR_SEGMENT_RANGES[index], radial && index % 2 == 1)
      end

      def self.star_group(group_index)
        first_segment = group_index * 2
        star_segment(first_segment) + star_segment(first_segment + 1)
      end

      def self.musical_groups(direction = :right)
        order = direction == :left ? [4, 3, 2, 1, 0] : MUSICAL_GROUP_ORDER
        result = []
        index = 0
        while index < order.length
          result << star_group(order[index])
          index += 1
        end
        result
      end

      def self.star_rays
        rays = []
        index = 0
        while index < STAR_SEGMENT_RANGES.length
          rays << star_segment(index, true)
          index += 1
        end
        rays
      end

      def self.parallel_segments(side)
        indices = side == :left ? PARALLEL_LEFT : PARALLEL_RIGHT
        result = []
        index = 0
        while index < indices.length
          result << star_segment(indices[index])
          index += 1
        end
        result
      end
    end
  end
end
