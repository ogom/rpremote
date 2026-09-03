# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module Measurement
      class BeatDetector
        def initialize(
          smooth_samples: Config::SMOOTH_SAMPLES,
          baseline_samples: Config::BASELINE_SAMPLES,
          hysteresis: Config::BEAT_HYSTERESIS,
          min_interval_ms: Config::MIN_BEAT_INTERVAL_MS,
          max_interval_ms: Config::MAX_BEAT_INTERVAL_MS,
          stabilize_ms: Config::STABILIZE_MS
        )
          @smooth = RollingSampleWindow.new(smooth_samples)
          @baseline = RollingSampleWindow.new(baseline_samples)
          @baseline_samples = baseline_samples
          @hysteresis = hysteresis
          @min_interval_ms = min_interval_ms
          @max_interval_ms = max_interval_ms
          @stabilize_ms = stabilize_ms
          clear
        end

        def start(timestamp_ms)
          clear
          @finger_detected_at = timestamp_ms
          @last_beat_at = timestamp_ms
          self
        end

        def process_sample(ir:, timestamp_ms:)
          @smooth.push(ir)
          smooth = @smooth.average
          @baseline.push(ir)
          baseline = @baseline.average

          if @baseline.count < @baseline_samples ||
             timestamp_ms - @finger_detected_at < @stabilize_ms
            @last_beat_at = timestamp_ms
            return
          end

          @crossed = false if smooth > baseline + @hysteresis
          return if @crossed || smooth >= baseline - @hysteresis

          @crossed = true
          interval_ms = timestamp_ms - @last_beat_at
          @last_beat_at = timestamp_ms
          {
            interval_ms: interval_ms,
            accepted: interval_ms > @min_interval_ms && interval_ms < @max_interval_ms
          }
        end

        def clear
          @smooth.clear
          @baseline.clear
          @finger_detected_at = 0
          @last_beat_at = 0
          @crossed = false
          self
        end
      end
    end
  end
end
