# frozen_string_literal: true

module Daisenkofun
  module Illumination
    class Display
      def initialize(strip)
        @strip = strip
        @pixels = []
        index = 0
        while index < LedLayout::LED_COUNT
          @pixels << Color::OFF
          index += 1
        end
      end

      def set(index, color, level = 1.0)
        validate_index(index)
        @pixels[index] = Color.scale(color, level)
      end

      def fill_range(first, last, color)
        validate_index(first)
        validate_index(last)
        scaled = Color.scale(color, 1.0)
        index = first
        while index <= last
          @pixels[index] = scaled
          index += 1
        end
      end

      def fill_indices(indices, color, level = 1.0)
        scaled = Color.scale(color, level)
        _fill_indices(@pixels, indices, scaled)
      end

      def fill_outline(outline_index, color, level = 1.0)
        fill_indices(LedLayout.outline_order(outline_index), color, level)
      end

      def attached(color, chayama_level, daianjiyama_level)
        set(LedLayout::CHAYAMA, color, chayama_level)
        set(LedLayout::DAIANJIYAMA, color, daianjiyama_level)
      end

      def scale_all(level)
        index = 0
        while index < @pixels.length
          @pixels[index] = Color.scale(@pixels[index], level)
          index += 1
        end
      end

      def clear_buffer
        _clear_pixels(@pixels)
      end

      def show
        _write_pixels(@strip, @pixels)
        @strip.show
      end

      def clear
        clear_buffer
        @strip.clear
      end

      # The mruby/c build replaces this fallback with one C call that copies the
      # packed frame directly into the WS2812 driver's RGB buffer.
      if RUBY_ENGINE == "ruby"
        def _clear_pixels(pixels)
          index = 0
          while index < pixels.length
            pixels[index] = Color::OFF
            index += 1
          end
        end

        def _fill_indices(pixels, indices, color)
          index = 0
          while index < indices.length
            position = indices[index]
            validate_index(position)
            pixels[position] = color
            index += 1
          end
        end

        def _write_pixels(strip, pixels)
          if strip.respond_to?(:replace_pixels)
            strip.replace_pixels(pixels)
            return
          end

          index = 0
          while index < pixels.length
            color = pixels[index]
            strip.set_rgb(index, Color.red(color), Color.green(color), Color.blue(color))
            index += 1
          end
        end
      end

      private

      def validate_index(index)
        unless index.is_a?(Integer)
          raise TypeError, "pixel index must be an Integer"
        end
        if index < 0 || index >= LedLayout::LED_COUNT
          raise IndexError, "pixel index out of range"
        end
      end
    end
  end
end
