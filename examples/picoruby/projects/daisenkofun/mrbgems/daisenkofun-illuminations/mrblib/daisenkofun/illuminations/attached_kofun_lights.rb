# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class AttachedKofunLights < Base
      def call
        middle = LedLayout.outline_order(LedLayout::MIDDLE_BANK)
        inner = LedLayout.outline_order(LedLayout::INNER_BANK)
        each_loop do
          each_phase(7) do |phase|
            @display.clear_buffer
            draw_soft_base(Color::NIGHT_BLUE, 0.05)
            @display.attached(Color::SOFT_GOLD, sin_level(phase, 0.16, 0.46), sin_level(phase + 55, 0.16, 0.46))
            middle.each_with_index { |index, pos| @display.set(index, Color::SOFT_GOLD, sin_level(phase + pos * 5, 0.06, 0.20)) }
            inner.each_with_index { |index, pos| @display.set(index, Color::WATER_BLUE, sin_level(phase + 80 + pos * 4, 0.04, 0.16)) }
            show_frame
          end
        end
      end
    end
  end
end
