# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class StarryKofun < Base
      def call
        order = LedLayout.main_order
        @display.clear_buffer
        draw_soft_base(Color::TWILIGHT_INDIGO, 0.10)
        step = 0
        while step < 96 * @loops
          fade_trail(0.88)
          draw_soft_base(Color::TWILIGHT_INDIGO, 0.05)
          deterministic_sparks(order, Color::SOFT_WHITE, 5, step, 0.32)
          step % 7 == 0 ? @display.attached(Color::SOFT_WHITE, 0.42, 0.18) : pulse_attached(step * 6, Color::MOON_BLUE, 70, 0.08, 0.24)
          show_frame
          step += 1
        end
      end
    end
  end
end
