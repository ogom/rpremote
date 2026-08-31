# frozen_string_literal: true

require "ws2812-plus"

module Daisenkofun
  class Illumination
    def call(run_mode, only_key = nil)
      entries = Setlist.resolve(run_mode, only_key)
      strip = WS2812.new(
        pin: Config::LED_PIN,
        num: LedLayout::LED_COUNT,
        order: Config::LED_ORDER
      )
      strip.brightness = Config::BRIGHTNESS_PERCENT

      begin
        call_patterns(strip, entries)
      ensure
        strip.clear
        strip.close
        puts "daisenkofun: LEDs off"
      end
    end

    private

    def call_patterns(strip, entries)
      index = 0

      while index < entries.length
        entry = entries[index]
        key = entry[Setlist::KEY]
        wait_ms = entry[Setlist::WAIT_MS]
        loops = entry[Setlist::LOOPS]
        puts "daisenkofun: pattern #{index + 1}/#{entries.length} #{key} wait_ms=#{wait_ms} loops=#{loops}"
        strip.clear
        call_pattern(strip, key, wait_ms, loops)
        index += 1
      end
    end

    def call_pattern(strip, key, wait_ms, loops)
      klass = pattern_class(key)
      klass.new(Display.new(strip), wait_ms, loops).call
    end

    def pattern_class(key)
      Setlist.pattern_class(key)
    end
  end
end
