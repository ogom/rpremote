# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class Breathing < Base
        STEPS = 60

        def call
          order = LedLayout.all_order
          each_loop do
            step = 0
            while step < STEPS
              @display.fill_indices(order, Color::GOLD, Config::BRIGHTNESS * step / STEPS.to_f)
              show_frame
              step += 1
            end
            step = 0
            while step < STEPS
              @display.fill_indices(order, Color::GOLD, Config::BRIGHTNESS * (STEPS - step) / STEPS.to_f)
              show_frame
              step += 1
            end
          end
        end
      end
    end
  end
end
