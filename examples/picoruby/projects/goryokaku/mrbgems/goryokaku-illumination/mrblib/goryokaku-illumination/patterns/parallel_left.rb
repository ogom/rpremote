# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class ParallelLeft < Base
        def call
          draw_segments(LedLayout.parallel_segments(:left))
        end

        private

        def draw_segments(segments)
          each_loop do
            position = 0
            while position < 18
              @display.scale_all(0.72)
              index = 0
              while index < segments.length
                @display.set(segments[index][position], Color.rainbow(index), Config::BRIGHTNESS) if position < segments[index].length
                index += 1
              end
              show_frame
              position += 1
            end
          end
        end
      end
    end
  end
end
