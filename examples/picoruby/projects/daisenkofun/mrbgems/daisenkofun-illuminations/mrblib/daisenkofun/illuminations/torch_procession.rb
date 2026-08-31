# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class TorchProcession < Base
      def call
        order = LedLayout.outside_to_inside_order
        each_loop do
          head = 0
          while head < order.length
            fade_trail(0.88)
            torch = 0
            while torch < 5
              position = (head - torch * 18) % order.length
              @display.set(order[position], Color::SOFT_GOLD, 0.34)
              @display.set(order[position - 1], Color::SUNRISE_ORANGE, 0.18) if position > 0
              torch += 1
            end
            arrival_marker(head, order.length, Color::SOFT_GOLD)
            show_frame
            head += 2
          end
        end
      end
    end
  end
end
