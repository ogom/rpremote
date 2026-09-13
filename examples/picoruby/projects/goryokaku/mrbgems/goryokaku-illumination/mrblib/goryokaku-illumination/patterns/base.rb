# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Base
        def initialize(display, wait_ms = Config::FRAME_INTERVAL_MS, loops = 1)
          @display = display
          @wait_ms = wait_ms
          @loops = loops
        end

        private

        def each_loop
          index = 0
          while index < @loops
            yield index
            index += 1
          end
        end

        def show_frame
          @display.show
          @display.wait_ms(@wait_ms)
        end

        def fade_zone(zone, color, from, to, steps)
          step = 0
          while step <= steps
            amount = from + (to - from) * step / steps.to_f
            @display.fill_zone(zone, color, amount)
            show_frame
            step += 1
          end
        end

        def draw_comet(order, head, color, tail_length, level = Config::BRIGHTNESS)
          tail = 0
          while tail < tail_length
            position = head - tail
            if position >= 0 && position < order.length
              @display.set(order[position], color, level * (tail_length - tail) / tail_length.to_f)
            end
            tail += 1
          end
        end

        def pseudo(seed, range)
          ((seed * 1103515245 + 12345) & 0x7fffffff) % range
        end
      end
    end
  end
end
