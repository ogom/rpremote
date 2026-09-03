# frozen_string_literal: true

require_relative "test_helper"

class DaisenkofunOximeterFactoryI2C
  class << self
    attr_reader :options

    def new(**options)
      @options = options
      :i2c
    end
  end
end

class DaisenkofunOximeterFactorySensor
  class << self
    attr_reader :i2c

    def new(i2c:)
      @i2c = i2c
      :sensor
    end
  end
end

class DaisenkofunOximeterSensorFactoryTest < Picotest::Test
  def test_injects_i2c_and_max30102_implementations
    factory = Daisenkofun::Oximeter::SensorFactory.new(
      i2c_class: DaisenkofunOximeterFactoryI2C,
      sensor_class: DaisenkofunOximeterFactorySensor
    )

    assert_equal :sensor, factory.call
    assert_equal :i2c, DaisenkofunOximeterFactorySensor.i2c
    assert_equal({
      unit: Daisenkofun::Oximeter::Config::I2C_UNIT,
      sda_pin: Daisenkofun::Oximeter::Config::I2C_SDA_PIN,
      scl_pin: Daisenkofun::Oximeter::Config::I2C_SCL_PIN,
      frequency: Daisenkofun::Oximeter::Config::I2C_FREQUENCY
    }, DaisenkofunOximeterFactoryI2C.options)
  end
end
