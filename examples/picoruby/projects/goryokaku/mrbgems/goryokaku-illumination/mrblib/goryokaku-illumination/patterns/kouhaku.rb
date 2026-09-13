# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Kouhaku < Base
        def call
          order = LedLayout.all_order
          each_loop do
            frame = 0
            while frame < 12
              index = 0
              while index < order.length
                color = (index + frame) % 2 == 0 ? Color::RED : Color::WHITE
                @display.set(order[index], color, Config::BRIGHTNESS)
                index += 1
              end
              show_frame
              frame += 1
            end
          end
        end
      end
    end
  end
end
