# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class Sunrise < Base
      def call
        each_loop do
          step = 0
          while step < 36
            @display.clear_buffer
            amount = step / 35.0
            sky = if amount < 0.5
              Color.blend(Color::TWILIGHT_INDIGO, Color::DAWN_ROSE, amount * 2.0)
            else
              Color.blend(Color::DAWN_ROSE, Color::SOFT_GOLD, (amount - 0.5) * 2.0)
            end

            each_outline do |outline_index|
              threshold = (LedLayout::OUTLINE_COUNT - outline_index - 1) * 0.12
              level = amount >= threshold ? 0.12 + amount * 0.22 : 0.04
              @display.fill_outline(outline_index, sky, level)
            end
            @display.attached(sky, 0.12 + amount * 0.25, 0.10 + amount * 0.20)
            show_frame
            step += 1
          end
        end
      end
    end
  end
end
