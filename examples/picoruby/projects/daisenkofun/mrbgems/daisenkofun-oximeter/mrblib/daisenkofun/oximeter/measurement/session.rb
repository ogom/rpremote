# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module Measurement
      class Session
        attr_reader :latest_bpm, :latest_spo2

        def initialize(result_samples: Config::RESULT_SAMPLES)
          @beat_intervals = RollingSampleWindow.new(result_samples)
          @spo2_values = RollingSampleWindow.new(result_samples)
          @result_samples = result_samples
          clear
        end

        def record_beat(interval_ms)
          @beat_intervals.push(interval_ms)
          60_000.0 / @beat_intervals.average
        end

        def record_spo2(spo2, bpm:)
          @spo2_values.push(spo2)
          return if @beat_intervals.count < 3

          completed_now = !@complete && @beat_intervals.count >= @result_samples
          @latest_bpm = bpm
          @latest_spo2 = @spo2_values.average
          @complete = @beat_intervals.count >= @result_samples
          {
            bpm: @latest_bpm,
            spo2: @latest_spo2,
            complete: @complete,
            completed_now: completed_now
          }
        end

        def clear
          @beat_intervals.clear
          @spo2_values.clear
          @latest_bpm = 0.0
          @latest_spo2 = 0.0
          @complete = false
          self
        end
      end
    end
  end
end
