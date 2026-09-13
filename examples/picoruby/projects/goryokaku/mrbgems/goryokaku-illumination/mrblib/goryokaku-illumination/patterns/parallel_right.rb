# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class ParallelRight < ParallelLeft
        def call
          draw_segments(LedLayout.parallel_segments(:right))
        end
      end
    end
  end
end
