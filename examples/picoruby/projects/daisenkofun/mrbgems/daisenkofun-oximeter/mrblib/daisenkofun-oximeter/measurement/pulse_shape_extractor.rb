# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module Measurement
      # Summarizes the inverted IR pulse between consecutive trough crossings.
      class PulseShapeExtractor
        MAX_SAMPLES = 200

        def initialize(min_samples: 8, min_amplitude: Config::BEAT_HYSTERESIS * 2)
          @min_samples = min_samples
          @min_amplitude = min_amplitude
          reset
        end

        def push(ir)
          return self unless ir.is_a?(Integer) || ir.is_a?(Float)

          @samples.shift if @samples.length >= MAX_SAMPLES
          @samples << ir
          self
        end

        def finish(interval_ms)
          samples = @samples
          @samples = []
          unless @has_boundary
            @has_boundary = true
            return
          end
          return unless interval_ms.is_a?(Integer) && interval_ms > 0
          return if samples.length < @min_samples

          minimum = samples[0]
          maximum = samples[0]
          minimum_index = 0
          index = 1
          while index < samples.length
            value = samples[index]
            if value < minimum
              minimum = value
              minimum_index = index
            end
            maximum = value if value > maximum
            index += 1
          end

          amplitude = maximum - minimum
          return if amplitude < @min_amplitude

          half_level = minimum + amplitude / 2.0
          left = minimum_index
          left -= 1 while left > 0 && samples[left - 1] <= half_level
          right = minimum_index
          right += 1 while right + 1 < samples.length && samples[right + 1] <= half_level
          width_samples = right - left + 1
          ratio = width_samples.to_f / samples.length

          { pulse_width_ratio: ratio, pulse_width_ms: (interval_ms * ratio).round, pulse_amplitude: amplitude, pulse_samples: samples.length }
        end

        def reset
          @samples = []
          @has_boundary = false
          self
        end
      end
    end
  end
end
