# frozen_string_literal: true

require "dfu"
require "my_gems"

APP_VERSION = "1.0.0"
LED_PIN = 25
BLINKS = 3
INTERVAL_MS = 500

puts "my_gems DFU app: starting v#{APP_VERSION}"

# Constructing MyGems initializes GPIO; confirm only after the LED is in a known safe state.
led = MyGems.new(pin: LED_PIN)
led.led_off
DFU.confirm

puts "my_gems DFU app: confirmed v#{APP_VERSION}"
BLINKS.times do
  led.led_on
  sleep_ms(INTERVAL_MS)
  led.led_off
  sleep_ms(INTERVAL_MS)
end

puts "my_gems DFU app v#{APP_VERSION}: OK"
