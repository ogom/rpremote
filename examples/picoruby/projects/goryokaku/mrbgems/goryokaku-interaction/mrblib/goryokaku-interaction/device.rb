# frozen_string_literal: true
module Goryokaku
  module Interaction
    class Device
      def initialize(touch: nil, motion: nil, touch_pin:, i2c_unit:, i2c_frequency:, i2c_sda_pin:, i2c_scl_pin:)
        @touch = touch
        @motion = motion
        @touch_pin = touch_pin
        @i2c_unit = i2c_unit
        @i2c_frequency = i2c_frequency
        @i2c_sda_pin = i2c_sda_pin
        @i2c_scl_pin = i2c_scl_pin
      end

      def open
        require "gpio" if @touch_pin
        require "i2c"
        require "mpu6050"
        @touch ||= GPIO.new(@touch_pin, GPIO::IN | GPIO::PULL_UP) if @touch_pin
        unless @motion
          i2c = I2C.new(unit: @i2c_unit, frequency: @i2c_frequency, sda_pin: @i2c_sda_pin, scl_pin: @i2c_scl_pin)
          @motion = MPU6050.new(i2c: i2c)
        end
        self
      end

      def touch_state; @touch ? @touch.read : 1; end
      def sample; @motion.read; end
      def acceleration; sample[:acceleration]; end
      def close; self; end
    end
  end
end
