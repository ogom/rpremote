# frozen_string_literal: true

require "ws2812-plus"

module Daisenkofun
  # Owns the 572-LED strip while an asynchronous beat pattern is running.
  class BeatIllumination
    def initialize(strip: nil, pattern: nil, logger: nil)
      @strip = strip
      @pattern = pattern || AsyncIlluminations::BeatPulse.new
      @logger = logger
      @display = nil
      @started = false
      @stopped = false
    end

    def start
      return self if @started

      @strip ||= WS2812.new(
        pin: Config::LED_PIN,
        num: LedLayout::LED_COUNT,
        order: Config::LED_ORDER
      )
      @strip.brightness = Config::BRIGHTNESS_PERCENT
      @display = Display.new(@strip)
      @display.clear
      @started = true
      @stopped = false
      log("DAISENKOFUN mode=combined component=beat_illumination event=start")
      self
    end

    def call(event, payload)
      @pattern.beat(payload) if event == :beat
      self
    end

    def tick(now)
      return self unless @started && !@stopped

      @pattern.tick(@display, now)
      self
    end

    def stop
      return self if @stopped

      strip = @strip
      @strip = nil
      begin
        if strip
          begin
            strip.clear
          ensure
            strip.close
          end
        end
      ensure
        @stopped = true
        @started = false
        log("DAISENKOFUN mode=combined component=beat_illumination event=stop")
      end
      self
    end

    private

    def log(message)
      if @logger
        @logger.puts(message)
      else
        puts message
      end
    end
  end
end
