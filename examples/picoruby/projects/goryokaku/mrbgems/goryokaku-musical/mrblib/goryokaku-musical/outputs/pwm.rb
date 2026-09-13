# frozen_string_literal: true
module Goryokaku
  module Musical
    module Outputs
      class Pwm < Base
        def initialize(pin:, pwm: nil)
          @pin = pin
          @pwm = pwm
        end
        def start
          unless @pwm
            require "pwm"
            @pwm = ::PWM.new(@pin)
          end
          @pwm.duty(0)
          self
        end
        def play(frequency, volume)
          start unless @pwm
          return stop if frequency == 0
          @pwm.frequency(frequency)
          @pwm.duty(volume)
        end
        def stop; @pwm.duty(0) if @pwm; end
      end
    end
  end
end
