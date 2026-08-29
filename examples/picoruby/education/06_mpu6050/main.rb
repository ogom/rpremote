# frozen_string_literal: true

require "ws2812-plus"
require "i2c"
require "mpu6050"
require "pwm"

SDA_PIN = 16
SCL_PIN = 17
LED_PIN = 14
SPEAKER_PIN = 18
SAMPLES = 40
SAMPLE_INTERVAL_MS = 150
MOVEMENT_THRESHOLD = 0.5

def orientation(acceleration)
  ax, ay, az = acceleration
  if ay.abs < 0.18 && ax.abs < 0.18 && az.abs > 0.8
    [[0, 255, 0], "level"]
  elsif ay.abs >= ax.abs
    [[255, 0, 0], "Y tilt"]
  else
    [[0, 0, 255], "X tilt"]
  end
end

def movement(changes)
  maximum = changes.max
  return nil unless maximum > MOVEMENT_THRESHOLD

  if maximum == changes[0]
    [[0, 0, 255], 3000, "X: shake", 60]
  elsif maximum == changes[1]
    [[255, 255, 0], 1000, "Y: pico", 60]
  else
    [[255, 0, 0], 150, "Z: don", 120]
  end
end

def play(speaker, frequency, duration_ms)
  speaker.frequency(frequency)
  speaker.duty(20)
  sleep_ms(duration_ms)
  speaker.duty(0)
end

i2c = I2C.new(unit: :RP2040_I2C0, sda_pin: SDA_PIN, scl_pin: SCL_PIN, frequency: 400_000)
sensor = MPU6050.new(i2c: i2c)

led = WS2812.new(pin: LED_PIN, num: 1)
led.brightness = 3
speaker = PWM.new(SPEAKER_PIN)
speaker.duty(0)
previous = sensor.read[:acceleration]

SAMPLES.times do |index|
  sample = sensor.read
  current = sample[:acceleration]
  gyroscope = sample[:gyroscope]
  changes = [
    (current[0] - previous[0]).abs,
    (current[1] - previous[1]).abs,
    (current[2] - previous[2]).abs
  ]
  event = movement(changes)

  if event
    color, frequency, mode, duration_ms = event
  else
    color, mode = orientation(current)
  end

  led.set_rgb(0, color[0], color[1], color[2])
  led.show
  play(speaker, frequency, duration_ms) if event
  puts "#{index + 1}: ax=#{current[0]}, ay=#{current[1]}, az=#{current[2]}, " \
       "gx=#{gyroscope[0]}, gy=#{gyroscope[1]}, gz=#{gyroscope[2]}, #{mode}"

  previous = current
  sleep_ms(SAMPLE_INTERVAL_MS)
end

speaker.duty(0)
led.clear
led.close
puts "mpu6050: OK"
