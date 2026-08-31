# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class SakaiSunset < Base
      def call
        each_loop do
          step = 0
          while step < 72
            @display.clear_buffer
            amount = step / 71.0
            sky = Color.blend(Color::AFTERGLOW_AMBER, Color::TWILIGHT_INDIGO, amount)
            horizon = Color.blend(Color::SUNRISE_ORANGE, Color::MEMORY_ROSE, amount)
            each_scene_row do |row, _row_index, row_amount|
              @display.fill_indices(row, Color.blend(sky, horizon, row_amount), 0.10 + (1.0 - amount) * 0.18 + row_amount * 0.08)
            end
            pulse_attached(step * 4, Color.blend(Color::AFTERGLOW_AMBER, Color::DAWN_ROSE, amount), 20, 0.10, 0.34)
            show_frame
            step += 1
          end
        end
      end
    end
  end
end
