# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module Measurement
      class FingerDetector
        def initialize(
          threshold: Config::FINGER_THRESHOLD,
          hysteresis: Config::FINGER_HYSTERESIS
        )
          @threshold = threshold
          @hysteresis = hysteresis
          @present = false
        end

        def update(ir)
          if @present
            return unless ir < @threshold - @hysteresis

            @present = false
            :removed
          else
            return unless ir > @threshold + @hysteresis

            @present = true
            :detected
          end
        end

        def present?
          @present
        end
      end
    end
  end
end
