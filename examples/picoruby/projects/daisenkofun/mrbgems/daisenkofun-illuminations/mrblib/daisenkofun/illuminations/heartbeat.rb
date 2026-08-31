# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Heartbeat < Base
      def call
        each_loop do
          beat = 0
          while beat < 72
            @display.clear_buffer
            level = 0.10 + sin_level(beat * 5, 0.0, 0.24) + sin_level(beat * 5 + 38, 0.0, 0.066)
            each_outline do |index|
              color = Color.blend(Color::MEMORY_ROSE, Color::SOFT_PINK, 0.45 + index * 0.08)
              @display.fill_outline(index, color, level)
            end
            @display.attached(Color::SOFT_PINK, level + 0.08, level + 0.05)
            show_frame
            beat += 1
          end
        end
      end
    end
  end
end
