# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class CarnivalChase < Base
      def call
        each_loop do
          step = 0
          while step < 190
            fade_trail(0.84)
            each_outline do |index|
              order = LedLayout.clockwise_order(index)
              color = Color::CARNIVAL[(step / 18 + index) % Color::CARNIVAL.length]
              draw_comet(order, (step + index * 17) % order.length, color, 10, 0.42)
            end
            color = Color::CARNIVAL[(step / 18) % Color::CARNIVAL.length]
            arrival_marker(step, 190, color)
            show_frame
            step += 2
          end
        end
      end
    end
  end
end
