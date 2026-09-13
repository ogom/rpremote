# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class WarmWhite < Base
        def call
          each_loop { fade_zone(LedLayout::STAR, Color::WARM_WHITE, 0.0, Config::BRIGHTNESS, 20) }
        end
      end
    end
  end
end
