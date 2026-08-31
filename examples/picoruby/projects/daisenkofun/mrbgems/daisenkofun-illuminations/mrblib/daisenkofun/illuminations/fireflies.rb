# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Fireflies < Base
      def call
        order = LedLayout.main_order
        @display.clear_buffer
        step = 0
        while step < 140 * @loops
          fade_trail(0.86)
          firefly = 0
          while firefly < 7
            position = (step * (firefly + 2) + firefly * 67) % order.length
            @display.set(order[position], Color::SOFT_GREEN, sin_level(step * 9 + firefly * 44, 0.16, 0.46))
            firefly += 1
          end
          pulse_attached(step * 7, Color::SOFT_GREEN, 95, 0.08, 0.36)
          show_frame
          step += 1
        end
      end
    end
  end
end
