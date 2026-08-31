# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class GreenShimmer < Base
      def call
        order = LedLayout.main_order
        each_loop do
          each_phase(7) do |phase|
            order.each_with_index { |index, pos| @display.set(index, Color::SOFT_GREEN, sin_level(phase + pos * 3, 0.08, 0.28)) }
            pulse_attached(phase + 30, Color::SOFT_GREEN, 45, 0.10, 0.34)
            show_frame
          end
        end
      end
    end
  end
end
