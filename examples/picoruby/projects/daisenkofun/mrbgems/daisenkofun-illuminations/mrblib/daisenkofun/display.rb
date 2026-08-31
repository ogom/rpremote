# frozen_string_literal: true

module Daisenkofun
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
      @pixels[index] = Color.scale(color, level)
    end

    def fill_range(first, last, color)
      index = first
      while index <= last
        set(index, color)
        index += 1
      end
    end

    def fill_indices(indices, color, level = 1.0)
      index = 0
      while index < indices.length
        set(indices[index], color, level)
        index += 1
      end
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
      index = 0
      while index < @pixels.length
        @pixels[index] = Color::OFF
        index += 1
      end
    end

    def show
      index = 0
      while index < @pixels.length
        color = @pixels[index]
        @strip.set_rgb(index, Color.red(color), Color.green(color), Color.blue(color))
        index += 1
      end
      @strip.show
    end

    def clear
      clear_buffer
      @strip.clear
    end
  end
end
