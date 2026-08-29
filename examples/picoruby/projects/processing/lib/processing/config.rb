# frozen_string_literal: true

# Select the IMU adapter used by both the DFU launcher and the stream task.
# Supported values: :mpu6050, :bmi270
module Processing
  module Config
    IMU_TYPE = :mpu6050
    IMU_ADDRESS = 0x68

    I2C_UNIT = :RP2040_I2C0
    I2C_FREQUENCY = 400_000
    SDA_PIN = 16
    SCL_PIN = 17

    SAMPLE_RATE_HZ = 120
    LOG_RATE_HZ = 20
    CALIBRATION_SECONDS = 2
  end
end
