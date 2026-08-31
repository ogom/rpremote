# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class RoseGarden < Base
      def call
        each_loop do
          each_phase(8) do |phase|
            each_outline do |index|
              wave = sin_level(phase + index * 32, 0.0, 1.0)
              @display.fill_outline(index, Color.blend(Color::TWILIGHT_INDIGO, Color::SOFT_PINK, wave), 0.10 + wave * 0.20)
            end
            pulse_attached(phase + 16, Color::SOFT_PINK, 16, 0.12, 0.36)
            show_frame
          end
        end
      end
    end
  end
end
