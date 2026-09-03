# frozen_string_literal: true

require "/lib/oximeter/measurement/events"
require "/lib/oximeter/status_led/states"

module Oximeter
  module StatusLed
    class Presenter
      def initialize(renderer)
        @renderer = renderer
        reset
      end

      def call(event, payload)
        case event
        when Measurement::Events::FINGER_DETECTED
          reset_measurement
          @mode = States::MEASURING
        when Measurement::Events::FINGER_REMOVED
          reset
        when Measurement::Events::BEAT
          @bpm = payload[:bpm]
          @last_beat_at = payload[:timestamp_ms]
        when Measurement::Events::MEASUREMENT_UPDATED
          update_measurement(payload)
        when Measurement::Events::MEASUREMENT_COMPLETED
          update_measurement(payload)
          @mode = States::RESULT
        end
        self
      end

      def tick(timestamp_ms)
        @renderer.render(
          @mode,
          timestamp_ms,
          spo2: @spo2,
          bpm: @bpm,
          last_beat_at: @last_beat_at
        )
        self
      end

      private

      def reset
        @mode = States::NO_FINGER
        reset_measurement
      end

      def reset_measurement
        @bpm = 0.0
        @spo2 = 0.0
        @last_beat_at = 0
      end

      def update_measurement(payload)
        @bpm = payload[:bpm]
        @spo2 = payload[:spo2]
        @mode = States::MEASURING unless @mode == States::RESULT
      end
    end
  end
end
