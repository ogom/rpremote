# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class RainbowComet < Base
      def call
        order = LedLayout.outside_to_inside_order
        each_loop do
          head = 0
          while head < order.length
            fade_trail(0.84)
            color = Color.rainbow(head / 12)
            draw_comet(order, head, color, 16, 0.50)
            arrival_marker(head, order.length, color)
            show_frame
            head += 3
          end
        end
      end
    end
  end
end
