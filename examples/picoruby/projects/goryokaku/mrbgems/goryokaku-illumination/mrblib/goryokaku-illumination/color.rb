# frozen_string_literal: true

module Goryokaku
  module Illumination
    module Color
      OFF = 0x000000
      WARM_WHITE = 0xFFB464
      SAKURA = 0xFF69B4
      RAVELIN = 0x00C8FF
      OUTER = 0xFFDC32
      WHITE = 0xFFFFFF
      RED = 0xFF0000
      GOLD = 0xFFA500
      YELLOW = 0xFFFF00
      BLUE = 0x0000FF
      LIGHT_PINK = 0xFFC0CB
      DEEP_PINK = 0xFF5096
      PETAL = 0xFFE0E0
      BUD_GREEN = 0x80A050
      SAKURA_PALETTE = [DEEP_PINK, SAKURA, LIGHT_PINK, PETAL, WHITE]
      RAINBOW = [0xFF0000, 0xFFA500, 0xFFFF00, 0x00FF00, 0x00C8FF, 0x0000FF, 0xFF00FF]
      FIREWORK = [0xFF321E, 0xFFC832, 0x64FF64, 0x32C8FF, 0xFF64FF, 0xFFFF96]

      def self.red(color)
        (color >> 16) & 0xff
      end

      def self.green(color)
        (color >> 8) & 0xff
      end

      def self.blue(color)
        color & 0xff
      end

      def self.rgb(red, green, blue)
        (red << 16) | (green << 8) | blue
      end

      def self.scale(color, level)
        level = 0.0 if level < 0.0
        level = 1.0 if level > 1.0
        rgb((red(color) * level).to_i, (green(color) * level).to_i, (blue(color) * level).to_i)
      end

      def self.blend(first, second, amount)
        amount = 0.0 if amount < 0.0
        amount = 1.0 if amount > 1.0
        rgb(
          (red(first) + (red(second) - red(first)) * amount).to_i,
          (green(first) + (green(second) - green(first)) * amount).to_i,
          (blue(first) + (blue(second) - blue(first)) * amount).to_i
        )
      end

      def self.rainbow(position)
        RAINBOW[position % RAINBOW.length]
      end
    end
  end
end
