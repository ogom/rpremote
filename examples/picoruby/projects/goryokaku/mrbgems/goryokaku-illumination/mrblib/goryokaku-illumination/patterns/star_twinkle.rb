# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class StarTwinkle < Base
        def call
          each_loop do |loop_index|
            frame = 0
            while frame < 60
              @display.clear_buffer
              @display.fill_zone(LedLayout::STAR, Color::WARM_WHITE, 0.04)
              spark = 0
              while spark < 18
                index = pseudo(loop_index * 101 + frame * 37 + spark * 53, 170)
                @display.set(index, Color::WHITE, 0.18 + (spark % 4) * 0.08)
                spark += 1
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
