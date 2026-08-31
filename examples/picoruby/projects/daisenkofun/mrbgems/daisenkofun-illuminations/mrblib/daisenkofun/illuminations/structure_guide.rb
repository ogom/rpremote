# frozen_string_literal: true

module Daisenkofun
  module Illuminations
    # Introduces the mound, moat boundaries, banks, and attached kofun
    # from the center of the model toward the outside.
    class StructureGuide < Base
      FADE_IN_STEPS = 16
      BANK_FADE_IN_STEPS = 12
      PULSE = [50, 63, 75, 85, 93, 98, 100, 98, 93, 85, 75, 63,
               50, 37, 25, 15, 7, 2, 0, 2, 7, 15, 25, 37]
      def call
        each_loop do
          show_mound_layers
          show_moats_and_banks
        end
      end

      private

      def show_mound_layers
        layer = 0
        while layer < LedLayout::MOUND_LAYER_COUNT
          step = 0
          while step < FADE_IN_STEPS
            @display.clear_buffer
            draw_structure_layers(layer, 6)
            level = 10 + step * 24 / (FADE_IN_STEPS - 1)
            fill_outline(layer, Color::STRUCTURE_LAYERS[layer], level)
            show_frame
            step += 1
          end
          layer += 1
        end
      end

      def show_moats_and_banks
        visible_count = LedLayout::MOUND_LAYER_COUNT
        moat = 0
        while moat < LedLayout::MOAT_BOUNDARIES.length
          pulse = 0
          while pulse <= 12
            @display.clear_buffer
            draw_structure_layers(visible_count, 6)
            draw_moat_boundary(moat, pulse)
            draw_attached_pair(pulse) if visible_count == Color::STRUCTURE_LAYERS.length
            show_frame
            pulse += 1
          end

          if visible_count < Color::STRUCTURE_LAYERS.length
            fade_in_bank(visible_count)
            visible_count += 1
          end
          moat += 1
        end
      end

      def fade_in_bank(layer)
        step = 0
        while step < BANK_FADE_IN_STEPS
          @display.clear_buffer
          draw_structure_layers(layer, 6)
          level = 10 + step * 22 / (BANK_FADE_IN_STEPS - 1)
          fill_outline(layer, Color::STRUCTURE_LAYERS[layer], level)
          set_attached_pair(Color::SOFT_GOLD, level, level * 88 / 100) if layer == 4
          show_frame
          step += 1
        end
      end

      def draw_structure_layers(visible_count, level)
        layer = 0
        while layer < visible_count
          fill_outline(layer, Color::STRUCTURE_LAYERS[layer], level)
          layer += 1
        end
      end

      def draw_moat_boundary(moat, pulse)
        wave = PULSE[pulse]
        color = blend(Color::MOAT_DARK_BLUE, Color::WATER_BLUE, wave)
        boundary = LedLayout::MOAT_BOUNDARIES[moat]
        index = 0
        while index < boundary.length
          boundary_wave = PULSE[(pulse + index * 3) % PULSE.length]
          level = 10 + boundary_wave * 22 / 100
          fill_outline(boundary[index], color, level)
          index += 1
        end
      end

      def draw_attached_pair(pulse)
        chayama_level = 10 + PULSE[pulse] * 22 / 100
        daianjiyama_level = 10 + PULSE[(pulse + 2) % PULSE.length] * 22 / 100
        set_attached_pair(Color::SOFT_GOLD, chayama_level, daianjiyama_level)
      end

      def set_attached_pair(color, chayama_level, daianjiyama_level)
        @display.attached(color, chayama_level / 100.0, daianjiyama_level / 100.0)
      end

      def fill_outline(outline, color, level)
        @display.fill_outline(outline, color, level / 100.0)
      end

      def blend(first, second, amount)
        Color.blend(first, second, amount / 100.0)
      end
    end
  end
end
