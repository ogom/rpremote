# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Fireworks < Base
        def call
          rays = LedLayout.star_rays
          each_loop do |loop_index|
            position = 0
            while position < 18
              @display.scale_all(0.62)
              ray = 0
              while ray < rays.length
                if position < rays[ray].length
                  @display.set(rays[ray][position], Color::FIREWORK[(ray + loop_index) % Color::FIREWORK.length], Config::BRIGHTNESS)
                end
                ray += 1
              end
              show_frame
              position += 1
            end
            outer_flash(loop_index)
          end
        end

        private

        def outer_flash(color_index)
          step = 0
          while step <= 12
            level = Config::BRIGHTNESS * (12 - step) / 12.0
            @display.fill_zone(LedLayout::OUTER, Color::FIREWORK[color_index % Color::FIREWORK.length], level)
            show_frame
            step += 1
          end
        end
      end
    end
  end
end
