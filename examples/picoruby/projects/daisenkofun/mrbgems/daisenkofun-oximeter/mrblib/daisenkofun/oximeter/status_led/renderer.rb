# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module StatusLed
      class Renderer
        def initialize(pixels)
          @pixels = pixels
          @position = 0
          @last_frame = 0
        end

        def render(mode, timestamp_ms, spo2:, bpm:, last_beat_at:)
          interval = case mode
                     when States::NO_FINGER then Config::NO_FINGER_FRAME_INTERVAL_MS
                     when States::MEASURING then Config::MEASURING_FRAME_INTERVAL_MS
                     else Config::RESULT_FRAME_INTERVAL_MS
                     end
          return self if timestamp_ms - @last_frame < interval

          red, green, blue = color_for(mode, spo2)
          position = if mode == States::RESULT
                       result_position(timestamp_ms, bpm, last_beat_at)
                     else
                       @position
                     end
          render_pixels(position, red, green, blue)
          @position = (position + 1) % Config::LED_COUNT unless mode == States::RESULT
          @last_frame = timestamp_ms
          self
        end

        def error
          @pixels.fill(Config::LED_BRIGHTNESS, 0, 0).show
          self
        end

        def clear
          @pixels.clear
          self
        end

        private

        def color_for(mode, spo2)
          if mode == States::NO_FINGER
            dim = Config::LED_BRIGHTNESS / 2
            [dim, dim, dim]
          elsif mode == States::MEASURING
            [0, Config::LED_TRAIL_DIM, Config::LED_BRIGHTNESS]
          elsif spo2 >= Config::SPO2_GREEN_LIMIT
            [0, Config::LED_BRIGHTNESS, Config::LED_TRAIL_DIM]
          else
            [Config::LED_BRIGHTNESS, 0, 0]
          end
        end

        def render_pixels(position, red, green, blue)
          before = (position + Config::LED_COUNT - 1) % Config::LED_COUNT
          after = (position + 1) % Config::LED_COUNT
          @pixels.fill(0, 0, 0)
          @pixels.set_rgb(before, red / 4, green / 4, blue / 4)
          @pixels.set_rgb(position, red, green, blue)
          @pixels.set_rgb(after, red / 2, green / 2, blue / 2)
          @pixels.show
        end

        def result_position(timestamp_ms, bpm, last_beat_at)
          bpm = 40.0 if bpm < 40.0
          bpm = 180.0 if bpm > 180.0
          beat_period = (60_000.0 / bpm).to_i
          elapsed = (timestamp_ms - last_beat_at) % beat_period
          elapsed * Config::LED_COUNT / beat_period
        end
      end
    end
  end
end
