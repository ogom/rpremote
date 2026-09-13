# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Hanami < Base
        PETALS = [Color::SAKURA, Color::LIGHT_PINK, Color::DEEP_PINK, Color::PETAL]

        def call
          order = LedLayout.all_order
          each_loop do |loop_index|
            frame = 0
            while frame < 24
              index = 0
              while index < order.length
                if index % 3 == 0
                  seed = loop_index * 89 + frame * 41 + index
                  color = PETALS[pseudo(seed, PETALS.length)]
                  level = (0.34 + pseudo(seed + 30, 67) / 100.0) * Config::BRIGHTNESS
                  @display.set(order[index], color, level)
                else
                  color = (index + frame) % 2 == 0 ? Color::RED : Color::WHITE
                  @display.set(order[index], color, Config::BRIGHTNESS)
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
