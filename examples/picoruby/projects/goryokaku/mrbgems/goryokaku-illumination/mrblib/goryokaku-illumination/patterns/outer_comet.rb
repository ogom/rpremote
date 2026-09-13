# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class OuterComet < Base
        def call
          order = LedLayout.outer_order
          each_loop do
            head = 0
            while head < order.length
              @display.scale_all(0.72)
              draw_comet(order, head, Color::OUTER, 15)
              show_frame
              head += 3
            end
          end
        end
      end
    end
  end
end
