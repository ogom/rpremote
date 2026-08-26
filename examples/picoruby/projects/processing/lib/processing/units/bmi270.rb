# frozen_string_literal: true

require 'bmi270'
require '/lib/processing/units/base'
require '/lib/processing/config'

module Processing
  module Units
    class Bmi270 < Base
      def initialize(i2c)
        # BMI270 has no 120 Hz ODR. Use 200 Hz and sample it at the configured
        # 120 Hz application rate.
        sensor = BMI270.new(
          i2c: i2c,
          address: Config::IMU_ADDRESS,
          accel_range: :g2,
          gyro_range: :dps250,
          odr: :hz200
        )
        super(sensor, 'BMI270')
      end
    end
  end
end
