# frozen_string_literal: true

require "dfu"
require "my_gems"

APP_VERSION = "2.0.0"
LED_PIN = 25
PATTERNS = 3
PULSE_MS = 150
PAUSE_MS = 500

puts "my_gems DFU app: starting v#{APP_VERSION}"

# The embedded mrbgem is unchanged, so only this application needs to be delivered through DFU.
led = MyGems.new(pin: LED_PIN)
led.led_off
DFU.confirm

puts "my_gems DFU app: confirmed v#{APP_VERSION}"
PATTERNS.times do
  2.times do
    led.led_on
    sleep_ms(PULSE_MS)
    led.led_off
    sleep_ms(PULSE_MS)
  end
  sleep_ms(PAUSE_MS)
end

puts "my_gems DFU app v#{APP_VERSION}: OK"
