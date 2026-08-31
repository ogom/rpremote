# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class WaterRipples < Base
      def call
        each_loop do
          radius = 0
          while radius < LedLayout::OUTLINE_COUNT + 2
            @display.clear_buffer
            each_outline do |outline_index|
              distance = outline_index - radius
              distance = -distance if distance < 0
              if distance <= 1
                @display.fill_outline(outline_index, Color::WATER_BLUE, 0.28 - distance * 0.10)
              else
                @display.fill_outline(outline_index, Color::DEEP_WATER_BLUE, 0.05)
              end
            end
            attached_level = radius >= LedLayout::MIDDLE_BANK ? 0.32 : 0.10
            @display.attached(Color::WATER_BLUE, attached_level, attached_level * 0.78)
            show_frame
            radius += 1
          end
        end
      end
    end
  end
end
