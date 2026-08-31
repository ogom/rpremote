# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class JewelBox < Base
      def call
        each_loop do
          each_phase(8) do |phase|
            each_outline do |index|
              color = Color::JEWEL[(index + phase / 72) % Color::JEWEL.length]
              @display.fill_outline(index, color, sin_level(phase + index * 50, 0.12, 0.32))
            end
            pulse_attached(phase, Color::JEWEL[(phase / 72) % Color::JEWEL.length], 72, 0.12, 0.42)
            show_frame
          end
        end
      end
    end
  end
end
