# frozen_string_literal: true

require "i2c"
require "max30102"
require "/lib/oximeter/config"

module Oximeter
  class SensorFactory
    def initialize(i2c_class: I2C, sensor_class: MAX30102)
      @i2c_class = i2c_class
      @sensor_class = sensor_class
    end

    def call
      i2c = @i2c_class.new(
        unit: Config::I2C_UNIT,
        sda_pin: Config::I2C_SDA_PIN,
        scl_pin: Config::I2C_SCL_PIN,
        frequency: Config::I2C_FREQUENCY
      )
      @sensor_class.new(i2c: i2c)
    end
  end
end
