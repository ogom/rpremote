# frozen_string_literal: true

require '/lib/processing/config'
require '/lib/processing/units/base'

module Processing
  class Unit
    def self.build(i2c)
      case Config::IMU_TYPE
      when :mpu6050
        require '/lib/processing/units/mpu6050'
        Units::Mpu6050.new(i2c)
      when :bmi270
        require '/lib/processing/units/bmi270'
        Units::Bmi270.new(i2c)
      else
        raise ArgumentError, "unsupported IMU_TYPE: #{Config::IMU_TYPE.inspect}"
      end
    end
  end
end
