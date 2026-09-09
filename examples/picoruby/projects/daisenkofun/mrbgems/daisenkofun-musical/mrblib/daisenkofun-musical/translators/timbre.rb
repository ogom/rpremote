# frozen_string_literal: true

module Daisenkofun
  module Musical
    module Translators
      # Maps one normalized optical pulse width to PWM ON time in percent.
      class Timbre
      MIN_DUTY = 2.0
      MAX_DUTY = 6.0

      def initialize(default_duty: 3.0)
        @default_duty = default_duty
      end

      def translate(payload)
        ratio = payload[:pulse_width_ratio]
        unless (ratio.is_a?(Integer) || ratio.is_a?(Float)) && ratio >= 0.0 && ratio <= 1.0
          return { duty_percent: @default_duty, pulse_width_ratio: nil }
        end

        duty = MIN_DUTY + (MAX_DUTY - MIN_DUTY) * ratio
        {
          duty_percent: duty.round(1),
          pulse_width_ratio: ratio,
          pulse_width_ms: payload[:pulse_width_ms],
          pulse_amplitude: payload[:pulse_amplitude],
          pulse_samples: payload[:pulse_samples]
        }
      end
      end
    end
  end
end
