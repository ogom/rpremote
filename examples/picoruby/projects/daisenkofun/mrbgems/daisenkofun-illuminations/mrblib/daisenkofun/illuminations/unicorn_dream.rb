# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class UnicornDream < Base
      def call
        order = LedLayout.main_order
        each_loop do
          each_phase(6) do |phase|
            order.each_with_index do |index, position|
              color = Color::UNICORN[(position / 36 + phase / 42) % Color::UNICORN.length]
              @display.set(index, color, sin_level(phase + position * 2, 0.08, 0.26))
            end
            pulse_attached(phase + 24, Color::UNICORN[(phase / 42) % Color::UNICORN.length], 36, 0.10, 0.34)
            show_frame
          end
        end
      end
    end
  end
end
