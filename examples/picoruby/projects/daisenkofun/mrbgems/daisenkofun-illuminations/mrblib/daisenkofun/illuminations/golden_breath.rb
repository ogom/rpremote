# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class GoldenBreath < Base
      def call
        order = LedLayout.main_order
        each_loop do
          each_phase(6) do |phase|
            level = sin_level(phase, 0.10, 0.34)
            @display.fill_indices(order, Color::SOFT_GOLD, level)
            pulse_attached(phase, Color::SOFT_GOLD, 0, 0.14, 0.38)
            show_frame
          end
        end
      end
    end
  end
end
