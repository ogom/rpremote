# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class ShootingStar < Base
        TAIL_LENGTH = 5

        def call
          order = LedLayout.all_order
          each_loop do
            head = 0
            while head < order.length + TAIL_LENGTH
              @display.clear_buffer
              draw_comet(order, head, Color::GOLD, TAIL_LENGTH)
              show_frame
              head += 1
            end
          end
        end
      end
    end
  end
end
