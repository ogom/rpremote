# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Fireworks < Base
      def call
        order = LedLayout.main_order
        @display.clear_buffer
        burst = 0
        while burst < 10 * @loops
          center = (burst * 137 + 83) % order.length
          color = Color::FIREWORK[burst % Color::FIREWORK.length]
          @display.attached(color, 0.36, 0.24)
          radius = 0
          while radius < 22
            fade_trail(0.78)
            direction = -1
            while direction <= 1
              position = center + direction * radius
              if position >= 0 && position < order.length
                @display.set(
                  order[position],
                  color,
                  Config::MAX_FIREWORK_LEVEL * (22 - radius) / 22.0
                )
              end
              direction += 2
            end
            @display.set(order[center], Color::SOFT_WHITE, 0.28) if radius == 0
            show_frame
            radius += 3
          end
          fade = 0
          while fade < 8
            fade_trail(0.80)
            pulse_attached(burst * 30, color, 30, 0.06, 0.20)
            show_frame
            fade += 1
          end
          burst += 1
        end
      end
    end
  end
end
