# frozen_string_literal: true

require 'ws2812-plus'
require 'i2c'
require 'pwm'

MPU6050_ADDRESS = 0x68
POWER_MANAGEMENT = 0x6B
ACCELERATION_START = 0x3B
SDA_PIN = 16
SCL_PIN = 17
LED_PIN = 14
SPEAKER_PIN = 18
SAMPLES = 50
SAMPLE_INTERVAL_MS = 100
MOVEMENT_THRESHOLD = 0.5

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

def play(speaker, frequency, duration_ms)
  speaker.frequency(frequency)
  speaker.duty(20)
  sleep_ms(duration_ms)
  speaker.duty(0)
end

def movement(changes)
  maximum = changes.max
  return nil unless maximum > MOVEMENT_THRESHOLD

  if maximum == changes[0]
    [[0, 0, 255], 3000, 'X: shake', 60]
  elsif maximum == changes[1]
    [[255, 255, 0], 1000, 'Y: pico', 60]
  else
    [[255, 0, 0], 150, 'Z: don', 120]
  end
end

i2c = I2C.new(unit: :RP2040_I2C0, sda_pin: SDA_PIN, scl_pin: SCL_PIN, frequency: 400_000)
i2c.write(MPU6050_ADDRESS, POWER_MANAGEMENT, 0)
sleep_ms(100)

led = WS2812.new(pin: LED_PIN, num: 1)
led.brightness = 10
speaker = PWM.new(SPEAKER_PIN)
speaker.duty(0)
previous = read_acceleration(i2c)

SAMPLES.times do
  current = read_acceleration(i2c)
  changes = [
    (current[0] - previous[0]).abs,
    (current[1] - previous[1]).abs,
    (current[2] - previous[2]).abs
  ]
  event = movement(changes)
  if event
    led.set_rgb(0, event[0][0], event[0][1], event[0][2])
    led.show
    play(speaker, event[1], event[3])
    puts event[2]
  else
    led.set_rgb(0, 0, 255, 0)
    led.show
  end
  previous = current
  sleep_ms(SAMPLE_INTERVAL_MS)
end

speaker.duty(0)
led.clear
led.close
puts 'mpu6050 sound: OK'
