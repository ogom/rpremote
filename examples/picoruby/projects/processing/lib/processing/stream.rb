# frozen_string_literal: true

# 120 Hz IMU acquisition, 20 Hz serial telemetry. The quaternion is an
# IMU-only (accelerometer + gyroscope) estimate: yaw is relative to calibration
# and cannot be made absolute without a magnetometer.
require 'i2c'
require 'machine'
require '/lib/processing/gesture_detector'
require '/lib/processing/orientation'
require '/lib/processing/config'
require '/lib/processing/unit'

module Processing
  class Stream
    DATA_PREFIX = 'IMU_DATA'

    def initialize(telemetry: $stderr)
      @sample_rate_hz = Config::SAMPLE_RATE_HZ
      @sample_period_ms = 1000.0 / @sample_rate_hz
      @log_period_ms = 1000 / Config::LOG_RATE_HZ
      @telemetry = telemetry
      @sensor = Unit.build(build_i2c)
      @orientation = Orientation.new
      @gesture = GestureDetector.new
    end

    def run
      calibrate
      started_at = Machine.board_millis
      last_sample_at = started_at
      last_log_at = started_at
      next_sample_at = started_at.to_f
      loop do
        now = Machine.board_millis
        if now >= next_sample_at
          sample = @sensor.read
          last_log_at = process_sample(sample, now, started_at, last_sample_at, last_log_at)
          last_sample_at = now
          next_sample_at += @sample_period_ms
        else
          sleep_ms(1)
        end
      end
    end

    private

    def build_i2c
      I2C.new(
        unit: Config::I2C_UNIT,
        sda_pin: Config::SDA_PIN,
        scl_pin: Config::SCL_PIN,
        frequency: Config::I2C_FREQUENCY
      )
    end

    def calibrate
      sample_count = @sample_rate_hz * Config::CALIBRATION_SECONDS
      @telemetry.puts "IMU_CALIBRATING,sensor=#{@sensor.name},samples=#{sample_count},rate_hz=#{@sample_rate_hz}"
      bias = @sensor.calibrate_gyroscope(
        sample_rate_hz: @sample_rate_hz,
        seconds: Config::CALIBRATION_SECONDS
      )
      @telemetry.puts "IMU_CALIBRATED,sensor=#{@sensor.name},gx_bias=#{bias[0]},gy_bias=#{bias[1]},gz_bias=#{bias[2]},yaw_reference=RELATIVE"
      @telemetry.puts 'IMU_HEADER,sensor,timestamp_ms,temperature_c,ax_g,ay_g,az_g,gx_dps,gy_dps,gz_dps,q0,q1,q2,q3,roll_deg,pitch_deg,yaw_relative_deg,posture,gesture'
    end

    def process_sample(sample, now, started_at, last_sample_at, last_log_at)
      acceleration = sample[:acceleration]
      gyroscope = sample[:gyroscope]
      dt = (now - last_sample_at) / 1000.0
      dt = @sample_period_ms / 1000.0 if dt <= 0.0 || dt > 0.1
      @orientation.update(acceleration, gyroscope, dt)
      event, event_posture = @gesture.update(now, @orientation.roll, acceleration, gyroscope)
      return last_log_at if now - last_log_at < @log_period_ms

      posture = event == 'NONE' ? @gesture.posture : event_posture
      write_sample(sample, acceleration, gyroscope, now - started_at, posture, event)
      now
    end

    def write_sample(sample, acceleration, gyroscope, elapsed, posture, event)
      fields = [
        DATA_PREFIX, @sensor.name, elapsed, sample[:temperature],
        acceleration[0], acceleration[1], acceleration[2],
        gyroscope[0], gyroscope[1], gyroscope[2],
        @orientation.q0, @orientation.q1, @orientation.q2, @orientation.q3,
        @orientation.roll, @orientation.pitch, @orientation.yaw, posture, event
      ]
      @telemetry.puts fields.join(',')
    end
  end
end

# Sandbox.load_file executes this file as the background stream entry point.
Processing::Stream.new.run
