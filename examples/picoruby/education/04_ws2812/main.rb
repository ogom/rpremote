# frozen_string_literal: true

# Requires a custom PicoRuby firmware that includes picoruby-ws2812-plus.
# Build and flash it as described in docs/firmware.md before running this file.
require 'ws2812-plus'

LED_PIN = 14
BUTTON_PIN = 15
SAMPLES = 500
POLL_INTERVAL_MS = 20

# mruby/c (the custom R2P2 VM) does not implement Array#freeze.
COLORS = [
  [255, 0, 0],
  [255, 100, 0],
  [255, 200, 0],
  [0, 255, 0],
  [0, 0, 255],
  [75, 0, 130],
  [148, 0, 211]
]

led = WS2812.new(pin: LED_PIN, num: 1)
led.brightness = 10
button = GPIO.new(BUTTON_PIN, GPIO::IN | GPIO::PULL_UP)
index = 0
previously_pressed = false

SAMPLES.times do
  pressed = button.low?
  if pressed && !previously_pressed
    color = COLORS[index]
    led.set_rgb(0, color[0], color[1], color[2])
    led.show
    puts "color #{index + 1}/#{COLORS.length}"
    index = (index + 1) % COLORS.length
  end
  previously_pressed = pressed
  sleep_ms(POLL_INTERVAL_MS)
end

led.clear
led.close
puts 'ws2812: OK'
