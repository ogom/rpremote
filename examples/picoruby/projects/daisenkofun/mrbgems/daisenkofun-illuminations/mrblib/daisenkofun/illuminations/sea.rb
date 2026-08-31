# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Sea < Base
      def call
        each_loop do
          each_phase(6) do |phase|
            draw_row_wave(Color::DEEP_WATER_BLUE, Color::SOFT_BLUE, phase, 20, 0.10, 0.22)
            pulse_attached(phase + 40, Color::WATER_BLUE, 28, 0.10, 0.36)
            show_frame
          end
        end
      end
    end
  end
end
