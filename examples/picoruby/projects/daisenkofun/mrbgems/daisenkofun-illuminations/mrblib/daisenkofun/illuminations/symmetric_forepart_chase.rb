# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class SymmetricForepartChase < Base
      def call
        pairs = LedLayout.symmetric_forepart_pairs
        each_loop do
          head = 0
          while head < pairs.length
            fade_trail(0.86)
            tail = 0
            while tail < 8
              position = head - tail
              if position >= 0
                level = 0.42 * (8 - tail) / 8.0
                @display.set(pairs[position][0], Color::SOFT_BLUE, level)
                @display.set(pairs[position][1], Color::SOFT_BLUE, level)
              end
              tail += 1
            end
            arrival_marker(head, pairs.length, Color::SOFT_BLUE)
            show_frame
            head += 1
          end
        end
      end
    end
  end
end
