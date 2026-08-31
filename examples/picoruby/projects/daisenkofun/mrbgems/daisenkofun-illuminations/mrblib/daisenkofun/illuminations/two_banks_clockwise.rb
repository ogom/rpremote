# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class TwoBanksClockwise < Base
      def call
        inner = LedLayout.clockwise_order(LedLayout::INNER_BANK)
        middle = LedLayout.clockwise_order(LedLayout::MIDDLE_BANK)
        count = inner.length > middle.length ? inner.length : middle.length
        each_loop do
          head = 0
          while head < count
            fade_trail(0.86)
            draw_comet(inner, head % inner.length, Color::WATER_BLUE, 12, 0.40)
            draw_comet(middle, head % middle.length, Color::SOFT_GREEN, 12, 0.40)
            arrival_marker(head, middle.length, Color::SOFT_GREEN)
            show_frame
            head += 2
          end
        end
      end
    end
  end
end
