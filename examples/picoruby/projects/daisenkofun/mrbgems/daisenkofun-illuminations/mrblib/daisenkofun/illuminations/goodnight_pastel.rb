# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class GoodnightPastel < Base
      def call
        each_loop do
          each_phase(6) do |phase|
            level = sin_level(phase, 0.12, 0.32)
            fill_outline_palette(Color::PASTEL, level)
            pulse_attached(phase, Color::PASTEL[0], 0, 0.12, 0.32)
            show_frame
          end
        end
      end
    end
  end
end
