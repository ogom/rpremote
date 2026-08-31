# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Aurora < Base
      def call
        each_loop do
          each_phase(6) do |phase|
            draw_row_wave(Color::SOFT_BLUE, Color::LAVENDER, phase, 24, 0.08, 0.22)
            pulse_attached(phase + 50, Color.blend(Color::SOFT_GREEN, Color::LAVENDER, sin_level(phase, 0.0, 1.0)), 50, 0.10, 0.34)
            show_frame
          end
        end
      end
    end
  end
end
