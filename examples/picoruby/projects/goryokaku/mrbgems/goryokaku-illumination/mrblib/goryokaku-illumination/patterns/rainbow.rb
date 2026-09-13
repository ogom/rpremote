# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Rainbow < Base
        def call
          each_loop do
            frame = 0
            while frame < 35
              segment = 0
              while segment < LedLayout::STAR_SEGMENT_RANGES.length
                @display.fill_indices(LedLayout.star_segment(segment), Color.rainbow(segment + frame), Config::BRIGHTNESS)
                segment += 1
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
