# frozen_string_literal: true

require "dfu"
require "i2c"
require "sandbox"
require "/lib/processing/config"
require "/lib/processing/unit"

stream_path = "/lib/processing/stream.rb"

# Stop both the current unit-based stream and the legacy MPU6050 stream
# before touching I2C. Otherwise a previous DFU task can read the bus while a
# newly selected sensor is uploading its initialization data.
if $imu_processing_stream
  $imu_processing_stream.close
  $imu_processing_stream = nil
end
if $mpu6050_processing_stream
  $mpu6050_processing_stream.close
  $mpu6050_processing_stream = nil
end

i2c = I2C.new(
  unit: Processing::Config::I2C_UNIT,
  sda_pin: Processing::Config::SDA_PIN,
  scl_pin: Processing::Config::SCL_PIN,
  frequency: Processing::Config::I2C_FREQUENCY
)
# Check the I2C device before confirming the staged DFU boot application.
unit = Processing::Unit.build(i2c)

# R2P2 loads a DFU boot application before it starts the Shell.  Running the
# endless serial loop here would therefore prevent `rpremote dfu status`,
# `rpremote fs`, and other Shell commands from working.  Run it in a Sandbox
# task instead, retain the Sandbox instance, and return to R2P2 startup.
unless File.exist?(stream_path)
  raise "Processing stream is missing: #{stream_path}"
end

# The previous stream was stopped before the sensor preflight, so it is now
# safe to hand I2C ownership to the new background task.
$imu_processing_stream = Sandbox.new("imu_processing")
$imu_processing_stream.load_file(stream_path, join: false)

# Confirm only a staged DFU boot application. `rpremote run` executes this
# launcher temporarily and must not turn an empty DFU slot into "confirmed".
dfu_status = DFU.status
dfu_slot = dfu_status["slot_#{dfu_status["try_slot"]}"]
DFU.confirm if dfu_slot && dfu_slot["ext"]
puts "#{unit.name} Processing stream started; R2P2 Shell remains available."
