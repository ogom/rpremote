# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Translators
      # C major pentatonic. Frequencies are requested PWM values, in Hz.
      class Pulse
      NOTES = [131, 147, 165, 196, 220, 262, 294, 330, 392, 440, 523, 587, 659, 784, 880]
      SPO2_MAX_AGE_MS = 5_000

      attr_reader :baseline, :direction

      def initialize
        reset
      end

      def reset
        @baseline_samples = []
        @baseline = nil
        @smoothed = nil
        @measurement_at = nil
        @direction = 0
        @note_index = nil
        self
      end

      def measurement(payload)
        value = payload[:spo2]
        at = payload[:timestamp_ms]
        unless (value.is_a?(Integer) || value.is_a?(Float)) && value > 0 && value <= 100 && at.is_a?(Integer)
          @measurement_at = nil
          @smoothed = nil
          @direction = 0
          return self
        end
        return self if @measurement_at && at <= @measurement_at

        if @measurement_at && at - @measurement_at > SPO2_MAX_AGE_MS
          @smoothed = nil
          @direction = 0
        end
        @measurement_at = at
        @smoothed = @smoothed ? @smoothed + 0.25 * (value - @smoothed) : value.to_f
        unless @baseline
          @baseline_samples << value
          if @baseline_samples.length == 8
            sorted = @baseline_samples.sort
            @baseline = (sorted[3] + sorted[4]) / 2.0
          end
        end
        self
      end

      def notes(interval_ms, timestamp_ms)
        return unless interval_ms.is_a?(Integer) && interval_ms > 350 && interval_ms < 1_500
        return unless timestamp_ms.is_a?(Integer)

        frequency = 256_000.0 / interval_ms
        select_note(frequency)
        update_direction(timestamp_ms)
        response_index = @note_index + @direction
        response_index = 0 if response_index < 0
        response_index = NOTES.length - 1 if response_index >= NOTES.length
        [NOTES[@note_index], NOTES[response_index]]
      end

      private

      def select_note(frequency)
        if @note_index
          lower = @note_index == 0 || frequency >= (NOTES[@note_index - 1] + NOTES[@note_index]) * 0.5 * 0.98
          upper = @note_index == NOTES.length - 1 || frequency <= (NOTES[@note_index] + NOTES[@note_index + 1]) * 0.5 * 1.02
          return if lower && upper
        end

        nearest = 0
        index = 1
        while index < NOTES.length
          if (NOTES[index] - frequency).abs < (NOTES[nearest] - frequency).abs
            nearest = index
          end
          index += 1
        end
        @note_index = nearest
      end

      def update_direction(timestamp_ms)
        unless @baseline && @measurement_at && timestamp_ms >= @measurement_at && timestamp_ms - @measurement_at <= SPO2_MAX_AGE_MS
          @direction = 0
          return
        end

        difference = @smoothed - @baseline
        if difference > 0.5
          @direction = 1
        elsif difference < -0.5
          @direction = -1
        elsif difference.abs <= 0.2
          @direction = 0
        end
      end
      end
    end
  end
end
