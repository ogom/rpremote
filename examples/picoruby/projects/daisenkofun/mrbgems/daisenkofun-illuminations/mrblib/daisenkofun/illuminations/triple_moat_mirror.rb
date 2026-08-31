# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    class TripleMoatMirror < Base
      def call
        each_loop do
          moat_index = 0
          while moat_index < LedLayout::MOAT_BOUNDARIES.length
            step = 0
            while step < 24
              @display.clear_buffer
              draw_structure(LedLayout::OUTLINE_COUNT, 0.035)
              @display.fill_outline(LedLayout::MOUND_TOP, Color::FOREST_CANOPY_GREEN, 0.20)
              @display.fill_outline(LedLayout::MOUND_MIDDLE, Color::FOREST_DEEP_GREEN, 0.17)

              previous = 0
              while previous < moat_index
                LedLayout::MOAT_BOUNDARIES[previous].each do |boundary|
                  @display.fill_outline(boundary, Color::DEEP_WATER_BLUE, 0.07)
                end
                previous += 1
              end

              level = pulse_level(step, 0.12, 0.32)
              LedLayout::MOAT_BOUNDARIES[moat_index].each do |boundary|
                @display.fill_outline(boundary, Color::WATER_BLUE, level)
              end
              @display.attached(Color::SOFT_WHITE, level * 0.82, level * 0.64)
              show_frame
              step += 1
            end
            moat_index += 1
          end
        end
      end
    end
  end
end
