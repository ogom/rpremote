# frozen_string_literal: true

module Goryokaku
  module Illumination
    class Display
      def initialize(strip, frame_waiter: nil)
        @strip = strip
        @frame_waiter = frame_waiter
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

      def fill_indices(indices, color, level = 1.0)
        _fill_indices(@pixels, indices, Color.scale(color, level))
      end

      def fill_zone(zone, color, level = 1.0)
        fill_indices(LedLayout.zone_order(zone), color, level)
      end

      def scale_all(level)
        index = 0
        while index < @pixels.length
          @pixels[index] = Color.scale(@pixels[index], level)
          index += 1
        end
      end

      def clear_buffer; _clear_pixels(@pixels); end

      def show
        _write_pixels(@strip, @pixels)
        @strip.show
      end

      def wait_ms(milliseconds)
        if @frame_waiter
          @frame_waiter.wait_ms(milliseconds)
        else
          sleep_ms(milliseconds)
        end
      end

      def clear
        clear_buffer
        @strip.clear
      end

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
        raise TypeError, "pixel index must be an Integer" unless index.is_a?(Integer)
        raise IndexError, "pixel index out of range" if index < 0 || index >= LedLayout::LED_COUNT
      end
    end
  end
end
