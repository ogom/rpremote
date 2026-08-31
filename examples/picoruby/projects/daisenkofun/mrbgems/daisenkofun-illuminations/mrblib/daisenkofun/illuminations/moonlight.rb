# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    # 月明かりが外側から墳丘へ広がる演出です。
    class Moonlight < Base
      def call
        each_loop do
          @display.clear

          outline_index = LedLayout::OUTLINE_COUNT - 1
          while outline_index >= 0
            range = LedLayout.outline_range(outline_index)
            @display.fill_range(range[0], range[1], Color::MOON_BLUE)
            show_frame
            outline_index -= 1
          end

          @display.set(LedLayout::CHAYAMA, Color::SOFT_WHITE)
          @display.set(LedLayout::DAIANJIYAMA, Color::MOON_BLUE)
          show_frame
        end
      end
    end
  end
end
