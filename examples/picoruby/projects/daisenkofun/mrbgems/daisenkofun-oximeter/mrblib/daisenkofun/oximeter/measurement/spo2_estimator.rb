# frozen_string_literal: true

module Daisenkofun
  module Oximeter
    module Measurement
      class SpO2Estimator
        attr_reader :count

        def initialize(
          signal_samples: Config::SIGNAL_SAMPLES,
          intercept: Config::SPO2_INTERCEPT,
          ratio_scale: Config::SPO2_RATIO_SCALE
        )
          @red_signal = RollingSampleWindow.new(signal_samples)
          @ir_signal = RollingSampleWindow.new(signal_samples)
          @signal_samples = signal_samples
          @intercept = intercept
          @ratio_scale = ratio_scale
          @count = 0
        end

        def push(red, ir)
          @red_signal.push(red)
          @ir_signal.push(ir)
          @count = @red_signal.count
          self
        end

        def estimate
          return if @red_signal.count < @signal_samples || @ir_signal.count < @signal_samples

          red_dc = @red_signal.average
          ir_dc = @ir_signal.average
          red_ac = @red_signal.standard_deviation
          ir_ac = @ir_signal.standard_deviation
          return if red_dc == 0.0 || ir_dc == 0.0 || ir_ac == 0.0

          ratio = (red_ac / red_dc) / (ir_ac / ir_dc)
          spo2 = @intercept - @ratio_scale * ratio
          spo2 = 0.0 if spo2 < 0.0
          spo2 = 100.0 if spo2 > 100.0
          spo2
        end

        def clear
          @red_signal.clear
          @ir_signal.clear
          @count = 0
          self
        end
      end
    end
  end
end
