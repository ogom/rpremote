# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class DappledLight < Base
      def call
        each_loop do
          step = 0
          while step < 36
            @display.clear_buffer
            @display.fill_outline(LedLayout::MOUND_TOP, Color::FOREST_CANOPY_GREEN, 0.20)
            @display.fill_outline(LedLayout::MOUND_MIDDLE, Color::FOREST_DEEP_GREEN, 0.18)
            @display.fill_outline(LedLayout::MOUND_BASE, Color::FOREST_CANOPY_GREEN, 0.14)
            @display.fill_outline(LedLayout::INNER_BANK, Color::FOREST_DEEP_GREEN, 0.10)
            @display.fill_outline(LedLayout::MIDDLE_BANK, Color::FOREST_DEEP_GREEN, 0.08)

            spark = 0
            while spark < 14
              index = (step * 47 + spark * 83) % 570
              level = 0.16 + (spark % 5) * 0.045
              @display.set(index, Color::FOREST_SUNLIGHT, level)
              spark += 1
            end
            level = pulse_level(step, 0.08, 0.28)
            @display.attached(Color::FOREST_SUNLIGHT, level, level * 0.72)
            show_frame
            step += 1
          end
        end
      end
    end
  end
end
