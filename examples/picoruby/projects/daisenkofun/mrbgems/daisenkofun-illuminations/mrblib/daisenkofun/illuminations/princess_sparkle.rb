# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class PrincessSparkle < Base
      def call
        order = LedLayout.main_order
        @display.clear_buffer
        step = 0
        while step < 120 * @loops
          fade_trail(0.88)
          fill_outline_palette(Color::PRINCESS, 0.07)
          deterministic_sparks(order, Color::SOFT_GOLD, 4, step, 0.34)
          pulse_attached(step * 6, Color::PRINCESS[(step / 18) % Color::PRINCESS.length], 48, 0.10, 0.40)
          show_frame
          step += 1
        end
      end
    end
  end
end
