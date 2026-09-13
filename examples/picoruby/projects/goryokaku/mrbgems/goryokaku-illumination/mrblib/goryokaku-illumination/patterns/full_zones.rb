# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class FullZones < Base
        def call
          each_loop do
            fade_zone(LedLayout::OUTER, Color::OUTER, 0.0, Config::BRIGHTNESS, 12)
            fade_zone(LedLayout::RAVELIN, Color::RAVELIN, 0.0, Config::BRIGHTNESS, 12)
            fade_zone(LedLayout::STAR, Color::WARM_WHITE, 0.0, Config::BRIGHTNESS, 12)
            fade_zone(LedLayout::STAR, Color::WARM_WHITE, Config::BRIGHTNESS, 0.0, 12)
            fade_zone(LedLayout::RAVELIN, Color::RAVELIN, Config::BRIGHTNESS, 0.0, 12)
            fade_zone(LedLayout::OUTER, Color::OUTER, Config::BRIGHTNESS, 0.0, 12)
          end
        end
      end
    end
  end
end
