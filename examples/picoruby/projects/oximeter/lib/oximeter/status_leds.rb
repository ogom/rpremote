# frozen_string_literal: true

require '/lib/oximeter/config'

module Oximeter
  class StatusLeds
    def initialize(pixels)
      @pixels = pixels
      @position = 0
      @last_frame = 0
    end

    def update(mode, now, spo2:, bpm:, last_beat_at:)
      interval = case mode
                 when :no_finger then 120
                 when :measuring then 90
                 else Config::RESULT_ANIMATION_INTERVAL_MS
                 end
      return if now - @last_frame < interval

      red, green, blue = color_for(mode, spo2)
      position = if mode == :result
                   result_position(now, bpm, last_beat_at)
                 else
                   @position
                 end
      render(position, red, green, blue)
      @position = (position + 1) % Config::LED_COUNT unless mode == :result
      @last_frame = now
    end

    def error
      @pixels.fill(Config::LED_BRIGHTNESS, 0, 0).show
    end

    def clear
      @pixels.clear
    end

    private

    def color_for(mode, spo2)
      if mode == :no_finger
        dim = Config::LED_BRIGHTNESS / 2
        [dim, dim, dim]
      elsif mode == :measuring
        [0, Config::LED_TRAIL_DIM, Config::LED_BRIGHTNESS]
      elsif spo2 >= Config::SPO2_GREEN_LIMIT
        [0, Config::LED_BRIGHTNESS, Config::LED_TRAIL_DIM]
      else
        [Config::LED_BRIGHTNESS, 0, 0]
      end
    end

    def render(position, red, green, blue)
      before = (position + Config::LED_COUNT - 1) % Config::LED_COUNT
      after = (position + 1) % Config::LED_COUNT
      @pixels.fill(0, 0, 0)
      @pixels.set_rgb(before, red / 4, green / 4, blue / 4)
      @pixels.set_rgb(position, red, green, blue)
      @pixels.set_rgb(after, red / 2, green / 2, blue / 2)
      @pixels.show
    end

    def result_position(now, bpm, last_beat_at)
      bpm = 40.0 if bpm < 40.0
      bpm = 180.0 if bpm > 180.0
      beat_period = (60_000.0 / bpm).to_i
      elapsed = (now - last_beat_at) % beat_period
      elapsed * Config::LED_COUNT / beat_period
    end
  end
end
