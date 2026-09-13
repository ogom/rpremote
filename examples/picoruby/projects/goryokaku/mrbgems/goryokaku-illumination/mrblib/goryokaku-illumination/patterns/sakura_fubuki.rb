# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class SakuraFubuki < Base
        def call
          order = LedLayout.all_order
          colors = [Color::SAKURA, Color::LIGHT_PINK, Color::DEEP_PINK, Color::PETAL]
          each_loop do |loop_index|
            frame = 0
            while frame < 60
              @display.clear_buffer
              index = 0
              while index < order.length
                seed = loop_index * 151 + frame * 59 + index * 97
                if pseudo(seed, 100) < 40
                  color = colors[pseudo(seed + 10, colors.length)]
                  level = (0.40 + pseudo(seed + 20, 61) / 100.0) * Config::BRIGHTNESS
                  @display.set(order[index], color, level)
                end
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
