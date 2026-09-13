# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class SakuraStream < Base
        TAIL_LENGTH = 4
        COLORS = [Color::SAKURA, Color::LIGHT_PINK, Color::PETAL]

        def call
          order = LedLayout.all_order
          each_loop do |loop_index|
            head = 0
            while head < order.length + TAIL_LENGTH
              @display.clear_buffer
              tail = 0
              while tail < TAIL_LENGTH
                position = head - tail
                if position >= 0 && position < order.length
                  color = COLORS[(loop_index + tail) % COLORS.length]
                  level = Config::BRIGHTNESS * (TAIL_LENGTH - tail) / TAIL_LENGTH.to_f
                  @display.set(order[position], color, level)
                end
                tail += 1
              end
              show_frame
              head += 1
            end
          end
        end
      end
    end
  end
end
