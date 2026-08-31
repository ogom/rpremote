# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class CherryBlossom < Base
      def call
        rows = LedLayout.scene_rows
        colors = [Color::MEMORY_ROSE, Color::SOFT_PINK, Color::SOFT_WHITE]
        @display.clear_buffer
        step = 0
        while step < 140 * @loops
          fade_trail(0.90)
          draw_soft_base(Color::TWILIGHT_INDIGO, 0.09)
          petal = 0
          while petal < 9
            row = rows[(step + petal * 5) % rows.length]
            @display.set(row[(step * 3 + petal * 11) % row.length], colors[petal % colors.length], 0.34)
            petal += 1
          end
          step % 18 < 9 ? @display.attached(Color::MEMORY_ROSE, 0.34, 0.20) : @display.attached(Color::DAWN_ROSE, 0.18, 0.34)
          show_frame
          step += 1
        end
      end
    end
  end
end
