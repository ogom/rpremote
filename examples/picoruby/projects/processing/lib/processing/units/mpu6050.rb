# frozen_string_literal: true

require 'mpu6050'
require '/lib/processing/units/base'
require '/lib/processing/config'

module Processing
  module Units
    class Mpu6050 < Base
      def initialize(i2c)
        sensor = MPU6050.new(
          i2c: i2c,
          address: Config::IMU_ADDRESS,
          accel_range: :g2,
          gyro_range: :dps250
        )
        super(sensor, 'MPU6050')
      end
    end
  end
end
