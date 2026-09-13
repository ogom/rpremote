# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Twinkle < Base
        def call
          order = LedLayout.all_order
          each_loop do |loop_index|
            frame = 0
            while frame < 60
              @display.clear_buffer
              index = 0
              while index < order.length
                if pseudo(loop_index * 131 + frame * 47 + index * 97, 100) < 30
                  level = 0.34 + pseudo(frame * 31 + index * 53, 67) / 100.0
                  @display.set(order[index], Color::GOLD, level * Config::BRIGHTNESS)
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
