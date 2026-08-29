# frozen_string_literal: true

module Processing
  module Units
    class Base
      def initialize(sensor, name)
        @sensor = sensor
        @name = name
        @gyro_bias = [0.0, 0.0, 0.0]
      end

      attr_reader :name, :gyro_bias

      # Keep the IMU still while sampling. This follows the SpresenseIMU
      # calibration model: average each gyro axis, retain the bias, and subtract
      # it from every subsequent reading.
      def calibrate_gyroscope(sample_rate_hz:, seconds:)
        sample_count = sample_rate_hz * seconds
        sample_period_ms = 1000.0 / sample_rate_hz
        sum = [0.0, 0.0, 0.0]
        sample_count.times do
          gyroscope = @sensor.read[:gyroscope]
          3.times { |i| sum[i] += gyroscope[i] }
          sleep_ms(sample_period_ms.round)
        end
        3.times { |i| @gyro_bias[i] = sum[i] / sample_count }
        @gyro_bias
      end

      # Every adapter returns acceleration in g, angular velocity in degrees per
      # second, and temperature in degrees Celsius.
      def read
        sample = @sensor.read
        gyroscope = sample[:gyroscope]
        {
          acceleration: sample[:acceleration],
          gyroscope: [
            gyroscope[0] - @gyro_bias[0],
            gyroscope[1] - @gyro_bias[1],
            gyroscope[2] - @gyro_bias[2]
          ],
          temperature: sample[:temperature]
        }
      end
    end
  end
end
