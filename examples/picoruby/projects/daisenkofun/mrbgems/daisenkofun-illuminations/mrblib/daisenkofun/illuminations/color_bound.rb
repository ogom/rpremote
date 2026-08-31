# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class ColorBound < Base
      def call
        order = LedLayout.main_order
        span = order.length - 1
        each_loop do
          step = 0
          while step < span * 2
            fade_trail(0.84)
            outward = step <= span
            position = outward ? step : span * 2 - step
            color = Color::CARNIVAL[(step / 46) % Color::CARNIVAL.length]
            tail = 0
            while tail < 12
              tail_position = outward ? position - tail : position + tail
              @display.set(order[tail_position], color, 0.42 * (12 - tail) / 12.0) if tail_position >= 0 && tail_position < order.length
              tail += 1
            end
            @display.attached(color, outward ? 0.32 : 0.16, outward ? 0.16 : 0.32)
            show_frame
            step += 4
          end
        end
      end
    end
  end
end
