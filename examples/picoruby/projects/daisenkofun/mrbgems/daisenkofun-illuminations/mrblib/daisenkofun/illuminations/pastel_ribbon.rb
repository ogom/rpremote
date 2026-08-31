# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class PastelRibbon < Base
      def call
        order = LedLayout.outside_to_inside_order
        each_loop do
          head = 0
          while head < order.length
            fade_trail(0.86)
            ribbon = 0
            while ribbon < 18
              color = Color::PASTEL[(head / 24 + ribbon / 6) % Color::PASTEL.length]
              @display.set(order[(head - ribbon) % order.length], color, 0.42 * (18 - ribbon) / 18.0)
              ribbon += 1
            end
            arrival_marker(head, order.length, Color::PASTEL[(head / 24) % Color::PASTEL.length])
            show_frame
            head += 4
          end
        end
      end
    end
  end
end
