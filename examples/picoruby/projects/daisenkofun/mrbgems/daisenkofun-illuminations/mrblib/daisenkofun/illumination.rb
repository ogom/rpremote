# frozen_string_literal: true

require "ws2812-plus"

module Daisenkofun
  class Illumination
    def initialize(logger: nil)
      @logger = logger
      @strip = nil
    end

    def play_setlist(setlist_name)
      play_entries(Setlist.resolve(setlist_name))
    end

    def play_pattern(pattern_key)
      entry = Setlist.entry_for(pattern_key)
      raise ArgumentError, "pattern_key must name a registered pattern" unless entry

      play_entries([entry])
    end

    def stop
      return self unless @strip

      strip = @strip
      @strip = nil
      begin
        begin
          strip.clear
        ensure
          strip.close
        end
      ensure
        log("DAISENKOFUN mode=illumination event=led_off")
      end
      self
    end

    private

    def play_entries(entries)
      @strip = WS2812.new(
        pin: Config::LED_PIN,
        num: LedLayout::LED_COUNT,
        order: Config::LED_ORDER
      )
      @strip.brightness = Config::BRIGHTNESS_PERCENT

      begin
        call_patterns(@strip, entries)
      ensure
        stop
      end
    end

    def call_patterns(strip, entries)
      index = 0

      while index < entries.length
        entry = entries[index]
        key = entry[Setlist::KEY]
        wait_ms = entry[Setlist::WAIT_MS]
        loops = entry[Setlist::LOOPS]
        log(
          "DAISENKOFUN mode=illumination event=pattern " \
          "index=#{index + 1}/#{entries.length} key=#{key} wait_ms=#{wait_ms} loops=#{loops}"
        )
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

    def log(message)
      if @logger
        @logger.puts(message)
      else
        puts message
      end
    end
  end
end
