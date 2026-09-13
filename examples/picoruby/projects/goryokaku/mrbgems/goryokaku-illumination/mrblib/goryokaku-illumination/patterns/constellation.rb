# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Constellation < Base
        def call
          order = LedLayout.all_order
          each_loop do |loop_index|
            frame = 0
            while frame < 24
              index = 0
              while index < order.length
                if index % 4 == 0
                  level = 0.34 + pseudo(loop_index * 79 + frame * 43 + index, 67) / 100.0
                  @display.set(order[index], Color::GOLD, level * Config::BRIGHTNESS)
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
