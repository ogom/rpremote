# frozen_string_literal: true

module Daisenkofun
  module Color
    OFF = 0x000000
    SOFT_WHITE = 0xD2B690
    SOFT_GOLD = 0xC88425
    SUNRISE_ORANGE = 0xD65A2E
    DAWN_ROSE = 0xC95475
    TWILIGHT_INDIGO = 0x241A52
    WATER_BLUE = 0x2B72B5
    DEEP_WATER_BLUE = 0x102A55
    FOREST_CANOPY_GREEN = 0x3B8F50
    FOREST_DEEP_GREEN = 0x1E5F34
    FOREST_SUNLIGHT = 0xC1A64A
    LAVENDER = 0x8C62B5
    SOFT_PINK = 0xCE6E99
    SOFT_BLUE = 0x568CC0
    SOFT_GREEN = 0x54A067
    MOON_BLUE = 0x5276A7
    NIGHT_BLUE = 0x121B3F
    AFTERGLOW_AMBER = 0xD47A35
    MEMORY_ROSE = 0xC97998
    MOAT_DARK_BLUE = 0x123A68

    RAINBOW = [
      0xD23F3F, 0xD27A32, 0xC8B43A, 0x4EA85A,
      0x3E82C4, 0x7058B8, 0xB8589A
    ]
    FIREWORK = [0xCF4934, 0xC95A87, 0xCB8D2A, SOFT_BLUE, LAVENDER, SOFT_GREEN]
    PASTEL = [0xC9799D, 0xA77BC2, 0x64A4C9, 0xC4A86F, 0x7DB78E]
    PRINCESS = [0xCE669B, 0xA06FC4, 0xC6A04D, 0x7FA7C8]
    JEWEL = [0xC84568, 0x4679C2, 0x329B64, 0x9957BC, 0xCC962D]
    UNICORN = [0xC97DA9, 0xAA84C7, 0x69AAC8, 0x83C5AD, 0xC6AE7A]
    CARNIVAL = [0xC94F4F, 0xCD7B23, 0xB9B13B, 0x3F9E5C, 0x3A80BE, 0x7955B8, 0xBF518E]

    MOUND_TOP = 0xCD9932
    MOUND_MIDDLE = 0xB07F30
    MOUND_BASE = 0x7D6F36
    INNER_BANK = 0x53A262
    MIDDLE_BANK = 0x378654
    STRUCTURE_LAYERS = [MOUND_TOP, MOUND_MIDDLE, MOUND_BASE, INNER_BANK, MIDDLE_BANK]

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
      red_value = (red(color) * level).to_i
      green_value = (green(color) * level).to_i
      blue_value = (blue(color) * level).to_i
      red_value = Config::MAX_COLOR_COMPONENT if red_value > Config::MAX_COLOR_COMPONENT
      green_value = Config::MAX_COLOR_COMPONENT if green_value > Config::MAX_COLOR_COMPONENT
      blue_value = Config::MAX_COLOR_COMPONENT if blue_value > Config::MAX_COLOR_COMPONENT

      total = red_value + green_value + blue_value
      if total > Config::MAX_COLOR_SUM
        factor = Config::MAX_COLOR_SUM.to_f / total
        red_value = (red_value * factor).to_i
        green_value = (green_value * factor).to_i
        blue_value = (blue_value * factor).to_i
      end
      rgb(red_value, green_value, blue_value)
    end

    def self.blend(first, second, amount)
      amount = 0.0 if amount < 0.0
      amount = 1.0 if amount > 1.0
      inverse = 1.0 - amount
      rgb(
        (red(first) * inverse + red(second) * amount).to_i,
        (green(first) * inverse + green(second) * amount).to_i,
        (blue(first) * inverse + blue(second) * amount).to_i
      )
    end

    def self.rainbow(position)
      RAINBOW[position % RAINBOW.length]
    end
  end
end
