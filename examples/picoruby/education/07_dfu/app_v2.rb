# frozen_string_literal: true

require 'dfu'

APP_VERSION = '2.0.0'
LED_PIN = 25
PATTERNS = 3
PULSE_MS = 150
PAUSE_MS = 500

puts "classroom beacon: starting v#{APP_VERSION}"

# Version 2 keeps the same startup self-check and changes the visible behavior to a double blink. Confirm only after initialization succeeds.
led = GPIO.new(LED_PIN, GPIO::OUT)
led.write(0)
DFU.confirm

puts "classroom beacon: confirmed v#{APP_VERSION}"
PATTERNS.times do
  2.times do
    led.write(1)
    sleep_ms(PULSE_MS)
    led.write(0)
    sleep_ms(PULSE_MS)
  end
  sleep_ms(PAUSE_MS)
end

puts "classroom beacon v#{APP_VERSION}: OK"
