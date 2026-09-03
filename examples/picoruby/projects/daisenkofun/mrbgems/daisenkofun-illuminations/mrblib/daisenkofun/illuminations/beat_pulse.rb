# frozen_string_literal: true

module Daisenkofun
  module AsyncIlluminations
    # A beat-driven pattern that renders at most one frame per tick.
    class BeatPulse
      FRAME_INTERVAL_MS = 50
      PULSE_DURATION_MS = 650

      def initialize(
        frame_interval_ms: FRAME_INTERVAL_MS,
        pulse_duration_ms: PULSE_DURATION_MS
      )
        @frame_interval_ms = frame_interval_ms
        @pulse_duration_ms = pulse_duration_ms
        @beat_at = nil
        @last_frame_at = nil
      end

      def beat(payload)
        @beat_at = payload[:timestamp_ms]
        @last_frame_at = nil
        self
      end

      def tick(display, now)
        return false unless @beat_at
        if @last_frame_at && now - @last_frame_at < @frame_interval_ms
          return false
        end

        elapsed = now - @beat_at
        display.clear_buffer
        if elapsed >= @pulse_duration_ms
          display.show
          @beat_at = nil
          @last_frame_at = now
          return true
        end

        level = pulse_level(elapsed)
        index = 0
        while index < LedLayout::OUTLINE_COUNT
          amount = 0.28 + index * 0.10
          color = Color.blend(Color::MEMORY_ROSE, Color::SOFT_PINK, amount)
          display.fill_outline(index, color, level)
          index += 1
        end
        display.attached(Color::SOFT_PINK, level + 0.08, level + 0.05)
        display.show
        @last_frame_at = now
        true
      end

      def pending?
        !@beat_at.nil?
      end

      private

      def pulse_level(elapsed)
        if elapsed < 90
          0.18 + 0.44 * elapsed / 90.0
        elsif elapsed < 190
          0.62 - 0.48 * (elapsed - 90) / 100.0
        elsif elapsed < 270
          0.14 + 0.28 * (elapsed - 190) / 80.0
        else
          0.42 - 0.39 * (elapsed - 270) / (@pulse_duration_ms - 270).to_f
        end
      end
    end
  end
end
