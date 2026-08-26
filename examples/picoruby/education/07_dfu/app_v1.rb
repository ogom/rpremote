# frozen_string_literal: true

require 'dfu'

APP_VERSION = '1.0.0'
LED_PIN = 25
BLINKS = 3
INTERVAL_MS = 500

puts "classroom beacon: starting v#{APP_VERSION}"

# Treat successful GPIO initialization as the startup self-check; an exception before DFU.confirm leaves this candidate unconfirmed for rollback.
led = GPIO.new(LED_PIN, GPIO::OUT)
led.write(0)
DFU.confirm

puts "classroom beacon: confirmed v#{APP_VERSION}"
BLINKS.times do
  led.write(1)
  sleep_ms(INTERVAL_MS)
  led.write(0)
  sleep_ms(INTERVAL_MS)
end

puts "classroom beacon v#{APP_VERSION}: OK"
