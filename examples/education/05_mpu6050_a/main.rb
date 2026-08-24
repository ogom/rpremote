# frozen_string_literal: true

require 'ws2812-plus'
require 'i2c'

MPU6050_ADDRESS = 0x68
POWER_MANAGEMENT = 0x6B
ACCELERATION_START = 0x3B
SDA_PIN = 16
SCL_PIN = 17
LED_PIN = 14
SAMPLES = 20
SAMPLE_INTERVAL_MS = 400

def signed16(high, low)
  value = (high << 8) | low
  value >= 0x8000 ? value - 0x1_0000 : value
end

def read_acceleration(i2c)
  i2c.write(MPU6050_ADDRESS, ACCELERATION_START, nostop: true)
  data = i2c.read(MPU6050_ADDRESS, 6).bytes
  [
    signed16(data[0], data[1]) / 16_384.0,
    signed16(data[2], data[3]) / 16_384.0,
    signed16(data[4], data[5]) / 16_384.0
  ]
end

i2c = I2C.new(unit: :RP2040_I2C0, sda_pin: SDA_PIN, scl_pin: SCL_PIN, frequency: 400_000)
i2c.write(MPU6050_ADDRESS, POWER_MANAGEMENT, 0)
sleep_ms(100)

led = WS2812.new(pin: LED_PIN, num: 1)
led.brightness = 10

SAMPLES.times do |index|
  ax, ay, az = read_acceleration(i2c)
  if ay.abs < 0.18 && ax.abs < 0.18 && az.abs > 0.8
    color = [0, 255, 0]
    mode = 'level'
  elsif ay.abs >= ax.abs
    color = [255, 0, 0]
    mode = 'Y tilt'
  else
    color = [0, 0, 255]
    mode = 'X tilt'
  end
  led.set_rgb(0, color[0], color[1], color[2])
  led.show
  puts "#{index + 1}: ax=#{ax}, ay=#{ay}, az=#{az}, #{mode}"
  sleep_ms(SAMPLE_INTERVAL_MS)
end

led.clear
led.close
puts 'mpu6050 tilt: OK'
