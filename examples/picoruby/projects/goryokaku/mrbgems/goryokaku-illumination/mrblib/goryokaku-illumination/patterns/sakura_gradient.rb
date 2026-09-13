# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class SakuraGradient < Base
        FRAMES = 120

        def call
          order = LedLayout.all_order
          palette = Color::SAKURA_PALETTE
          each_loop do |loop_index|
            frame = 0
            while frame < FRAMES
              index = 0
              while index < order.length
                scaled = ((index + frame + loop_index * FRAMES) % order.length) * (palette.length - 1) * 256 / order.length
                color_index = scaled / 256
                amount = (scaled % 256) / 255.0
                color_index = palette.length - 2 if color_index >= palette.length - 1
                @display.set(order[index], Color.blend(palette[color_index], palette[color_index + 1], amount), Config::BRIGHTNESS)
                index += 1
              end
              show_frame
              frame += 1
            end
          end
        end
      end
    end
  end
end
