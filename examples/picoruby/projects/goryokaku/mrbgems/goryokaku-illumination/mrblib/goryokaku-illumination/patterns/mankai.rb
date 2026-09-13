# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Mankai < Base
        def call
          order = LedLayout.all_order
          palette = Color::SAKURA_PALETTE
          each_loop do |loop_index|
            frame = 0
            while frame < 60
              index = 0
              while index < order.length
                seed = loop_index * 103 + frame * 37 + index * 97
                color = palette[pseudo(seed, palette.length)]
                level = (0.28 + pseudo(seed + 40, 73) / 100.0) * Config::BRIGHTNESS
                @display.set(order[index], color, level)
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
