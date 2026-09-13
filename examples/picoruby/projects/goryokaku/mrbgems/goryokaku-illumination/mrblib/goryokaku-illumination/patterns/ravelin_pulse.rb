# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class RavelinPulse < Base
        def call
          each_loop do
            pulse = 0
            while pulse < 4
              fade_zone(LedLayout::RAVELIN, Color::RAVELIN, 0.0, Config::BRIGHTNESS, 12)
              fade_zone(LedLayout::RAVELIN, Color::RAVELIN, Config::BRIGHTNESS, 0.0, 12)
              pulse += 1
            end
          end
        end
      end
    end
  end
end
