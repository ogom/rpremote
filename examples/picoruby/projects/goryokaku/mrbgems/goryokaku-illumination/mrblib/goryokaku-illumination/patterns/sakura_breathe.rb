# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Patterns
      class SakuraBreathe < Base
        def call
          each_loop do
            fade_zone(LedLayout::STAR, Color::SAKURA, 0.05, Config::BRIGHTNESS, 24)
            fade_zone(LedLayout::STAR, Color::SAKURA, Config::BRIGHTNESS, 0.05, 24)
          end
        end
      end
    end
  end
end
